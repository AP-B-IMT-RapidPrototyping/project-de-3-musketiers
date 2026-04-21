using Godot;

public partial class Gun : Node3D
{
    [Export] private Timer _fireRateTimer;
    [Export] private Node3D _weaponMount;
    [Export] private Marker3D _muzzle;

    public override void _Process(double delta)
    {
        // Volg de weapon mount position
        GlobalPosition = _weaponMount.GlobalPosition;
        GlobalRotation = _weaponMount.GlobalRotation;
    }

    public void OnShoot(RayCast3D raycast)
    {
        // Check of we nog in cooldown zitten
        if (!_fireRateTimer.IsStopped())
            return;

        // Start de cooldown timer
        _fireRateTimer.Start();

        // Bepaal het eindpunt van de beam
        Vector3 beamEnd = raycast.IsColliding()
            ? raycast.GetCollisionPoint()
            : _muzzle.GlobalPosition - raycast.GlobalBasis.Z * 100;

        // Teken de beam naar het hit point
        ShowBeam(_muzzle.GlobalPosition, beamEnd);

        // Check target hit
        if (raycast.GetCollider() is Target targetHit)
            targetHit.OnHit();

        GD.Print("Railgun fired!");
    }

    private void ShowBeam(Vector3 start, Vector3 end)
    {
        // Maak een cilinder mesh voor de beam
        var beamMesh = new CylinderMesh();
        beamMesh.TopRadius = 0.02f;
        beamMesh.BottomRadius = 0.02f;
        beamMesh.Height = 1.0f;

        var material = new StandardMaterial3D();
        material.ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded;
        material.AlbedoColor = Colors.Cyan;
        material.NoDepthTest = true;  // Teken altijd op de voorgrond

        var beamInstance = new MeshInstance3D
        {
            Mesh = beamMesh,
            MaterialOverride = material,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off
        };

        GetTree().Root.AddChild(beamInstance);

        // Positioneer en roteer de beam
        Vector3 direction = end - start;
        float distance = direction.Length();

        beamInstance.GlobalPosition = start + direction / 2;
        beamInstance.LookAt(end, Vector3.Up);
        beamInstance.RotateObjectLocal(Vector3.Right, Mathf.Pi / 2);
        beamInstance.Scale = new Vector3(1, distance, 1);

        // Verwijder na 0.05 seconden
        GetTree().CreateTimer(0.05).Timeout += () => beamInstance.QueueFree();
    }
}