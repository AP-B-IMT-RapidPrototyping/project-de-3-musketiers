using System.Runtime;
using Godot;


public partial class Gun : Node3D
{
    [Export] Marker3D _muzzle;
    [Export] private Timer _fireRateTimer;

    [Export] private Node3D _weaponMount;

    public override void _Process(double delta)
    {
        GlobalTransform = _weaponMount.GlobalTransform;
    }

    public void OnShoot(RayCast3D raycast)
    {
        if (!_fireRateTimer.IsStopped())
            return;


        _fireRateTimer.Start();

        Vector3 beamEnd = raycast.IsColliding()
        ? raycast.GetCollisionPoint()
        : _muzzle.GlobalPosition - raycast.GlobalBasis.Z * 100;

        ShowBeam(_muzzle.GlobalPosition, beamEnd);

        if (raycast.GetCollider() is Target targetHit)
            targetHit.OnHit();

        GD.Print("Railgun Fired!");
    }

    private void ShowBeam(Vector3 start, Vector3 end)
    {
        var beamMesh = new CylinderMesh();
        beamMesh.TopRadius = 0.02f;
        beamMesh.BottomRadius = 0.02f;
        beamMesh.Height = 1.0f;

        var material = new StandardMaterial3D();
        material.ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded;
        material.AlbedoColor = Colors.Red;

        var beamInstance = new MeshInstance3D
        {
            Mesh = beamMesh,
            MaterialOverride = material,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off
        };

        GetTree().Root.AddChild(beamInstance);

        Vector3 direction = end - start;
        float distance = direction.Length();

        beamInstance.GlobalPosition = start + direction / 2;
        beamInstance.LookAt(end, Vector3.Up);
        beamInstance.RotateObjectLocal(Vector3.Right, Mathf.Pi / 2);
        beamInstance.Scale = new Vector3(1, distance, 1);

        GetTree().CreateTimer(0.05).Timeout += () => beamInstance.QueueFree();
    }
}
