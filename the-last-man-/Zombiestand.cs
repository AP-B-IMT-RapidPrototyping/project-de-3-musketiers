using Godot;
using System;

public partial class Zombie : CharacterBody3D
{
	[Export] public float Speed = 2.0f;
	[Export] public int MaxHealth = 100;

	private int _currentHealth;
	private Vector3 _direction;

	public override void _Ready()
	{
		_currentHealth = MaxHealth;
		PickRandomDirection();
	}

	public override void _PhysicsProcess(double delta)
	{
		Velocity = _direction * Speed;
		MoveAndSlide();
	}

	private void PickRandomDirection()
	{
		float x = (float)GD.RandRange(-1, 1);
		float z = (float)GD.RandRange(-1, 1);

		_direction = new Vector3(x, 0, z).Normalized();

		if (_direction.Length() > 0)
			LookAt(GlobalPosition + _direction, Vector3.Up);
	}

	// 🔥 Wordt aangeroepen wanneer zombie geraakt wordt
	public void TakeDamage(int damage)
	{
		_currentHealth -= damage;

		GD.Print("Zombie HP: " + _currentHealth);

		if (_currentHealth <= 0)
		{
			Die();
		}
	}

	private void Die()
	{
		GD.Print("Zombie is dood!");

		QueueFree(); // verwijdert zombie uit scene
	}
}
