using Godot;

[GlobalClass]
public partial class Target : RigidBody3D
{
	[Export] private Node3D _root;

	public void OnHit()
	{
		GD.Print("Target destroyed!");

		// Verwijder de hele Target scene
		_root.QueueFree();
	}
}
