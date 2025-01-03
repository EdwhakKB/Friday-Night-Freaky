package states;

#if desktop
import backend.Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import lime.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef CreditsData = {
	var character:Array<Array<Dynamic>>;
}

class CreditsState extends MusicBeatState
{
	private var grpOptions:FlxTypedGroup<FlxSprite>;

	var curSelected:Int = 0;

	var creditsData:CreditsData;

	var bg:FlxSprite;
	var characterImage:FlxSprite;
	
	var descripcion:FlxText;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	//Names, Links, Offsets
	var characterData:Array<Array<Dynamic>> = [[], [], []];
	var image:FlxSprite = new FlxSprite(0, 0);

	override function create()
	{
		persistentUpdate = true;

		FlxG.mouse.visible = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.updateHitbox();
		add(bg);

		creditsData = Json.parse(Paths.getTextFromFile('images/creditmenu/Credits.json'));

		for (i in 0...creditsData.character.length) 
		{
			characterData[0].push(creditsData.character[i][0]);
			characterData[1].push(creditsData.character[i][1]);
			characterData[2].push(creditsData.character[i][2]);
		}

		image.setGraphicSize(FlxG.width, FlxG.height);
		image.loadGraphic(Paths.image("creditmenu/"+characterData[0][curSelected]));
		add(image);

		leftArrow = new FlxSprite(0, 0);
		leftArrow.frames = (Paths.getSparrowAtlas("creditmenu/Big_Arrows"));
		leftArrow.animation.addByPrefix('idle', "arrow_left");
		leftArrow.animation.addByPrefix('press', "press_left");
		leftArrow.animation.play('idle');
		add(leftArrow);

		rightArrow = new FlxSprite(0, 0);
		rightArrow.frames = (Paths.getSparrowAtlas("creditmenu/Big_Arrows"));
		rightArrow.animation.addByPrefix('idle', "arrow_right");
		rightArrow.animation.addByPrefix('press', "press_right");
		rightArrow.animation.play('idle');
		add(rightArrow);

		changeItem();

		super.create();
	}

	var selecto:Int = -1;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (controls.BACK || FlxG.mouse.pressedRight)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.UI_LEFT)
			leftArrow.animation.play('press');
		else
			leftArrow.animation.play('idle');

		if (controls.UI_RIGHT)
			rightArrow.animation.play('press');
		else
			rightArrow.animation.play('idle');

		if (controls.UI_LEFT_P)
			changeItem(-1);

		if (controls.UI_RIGHT_P)
			changeItem(1);

		if (controls.ACCEPT){
			FlxG.sound.play(Paths.sound('scrollMenu'));
			CoolUtil.browserLoad(characterData[1][curSelected]);
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));

		curSelected += huh;

		if (curSelected >= characterData[0].length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = characterData[0].length - 1;

		var offsets:Array<Float> = [0, 0];
		if (characterData[2][curSelected] != null)
			offsets = characterData[2][curSelected];
		image.setPosition(0, 0);
		image.x += offsets[0];
		image.y += offsets[1];
		image.setGraphicSize(FlxG.width, FlxG.height);
		image.loadGraphic(Paths.image("creditmenu/"+characterData[0][curSelected]));
	}
}
