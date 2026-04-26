 
using Godot;
using System;

public partial class MenuItems : Node3D
{
    [Export] private AnimationPlayer _animationPlayer;


    private void StartButton(Node camera, InputEvent @event, Vector3 position, Vector3 normal, int shapeIdx)
    {
        if (@event is InputEventMouseButton mouseEvent && mouseEvent.Pressed)
        {
            _animationPlayer.Play("PlayButton");
        }
    }

    private void QuitButton(Node camera, InputEvent @event, Vector3 position, Vector3 normal, int shapeIdx)
    {
        if (@event is InputEventMouseButton mouseEvent && mouseEvent.Pressed)
        {
            GetTree().Quit();
        }
    }

    private void Tutorial()
    {
        GetTree().ChangeSceneToFile("res://Scenes/Levels/tutorial.tscn");
    }

    private void Game()
    {
        GetTree().ChangeSceneToFile("res://yusuf/test.tscn");
    }

    private void Back()
    {
        _animationPlayer.PlayBackwards("PlayButton");
    }
}