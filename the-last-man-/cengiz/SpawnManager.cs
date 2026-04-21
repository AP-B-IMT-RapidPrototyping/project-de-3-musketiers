using Godot;
using Godot.Collections;

public partial class SpawnManager : Node
{
	[Export] private Array<Marker3D> _spawnPoints = new Array<Marker3D>();
	[Export] private PackedScene _enemyScene;

	private void SpawnEnemy()
	{
		if (_spawnPoints.Count == 0 || _enemyScene == null)
			return;

		// Kies een random spawn point
		int randomIndex = GD.RandRange(0, _spawnPoints.Count - 1);
		Marker3D spawnPoint = _spawnPoints[randomIndex];

		// Instantiate de enemy
		var enemy = _enemyScene.Instantiate<Node3D>();
		enemy.GlobalPosition = spawnPoint.GlobalPosition;

		// Voeg toe aan de scene
		GetTree().Root.AddChild(enemy);

		GD.Print($"Spawned enemy at {spawnPoint.Name}");
	}
}
