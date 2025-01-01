package options;

import states.MainMenuState;
import backend.StageData;
import flixel.FlxObject;
#if (target.threaded)
import sys.thread.Mutex;
import sys.thread.Thread;
#end

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note_Colors',
		'Controls',
		//'Adjust Delay and Combo',
		'Graphics',
		//'Visuals',
		'Gameplay'
		//'V-Slice Options',
		// #if TRANSLATIONS_ALLOWED  'Language', #end
		// #if (TOUCH_CONTROLS_ALLOWED || mobile)'Mobile Options' #end
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	#if (target.threaded) var mutex:Mutex = new Mutex(); #end

	private var mainCam:FlxCamera;
	public static var funnyCam:FlxCamera;
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;
	var menuItems:FlxTypedGroup<FlxSprite>;
	var bf:FlxSprite;
	var toolBox:FlxSprite;
	var optionThingy:FlxSprite;

	function openSelectedSubstate(label:String) {
		if (label != "Adjust Delay and Combo")
			funnyCam.visible = persistentUpdate = false;

		switch(label)
		{
			case 'Note_Colors':
				openSubState(new options.NotesColorSubState());
			case 'Controls':
				if (controls.mobileC)
				{
					funnyCam.visible = persistentUpdate = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
				else
					openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'V-Slice Options':
				openSubState(new BaseGameSubState());
			#if (TOUCH_CONTROLS_ALLOWED || mobile)
			case 'Mobile Options':
				openSubState(new mobile.options.MobileOptionsSubState());
			#end
			case 'Language':
				openSubState(new options.LanguageSubState());
		}
	}

	override function create()
	{
		mainCam = initPsychCamera();
		funnyCam = new FlxCamera();
		funnyCam.bgColor.alpha = 0;
		FlxG.cameras.add(funnyCam, false);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		FlxG.cameras.list[FlxG.cameras.list.indexOf(funnyCam)].follow(camFollowPos);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('optionsmenu/Options_BG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...options.length)
		{
			var offset:Float = 108 - (Math.max(options.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i) + offset/4 - offset/4);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.frames = Paths.getSparrowAtlas('optionsmenu/options_' + options[i].toLowerCase());
			menuItem.animation.addByPrefix('idle', options[i].toLowerCase() + " basic", 24);
			menuItem.animation.addByPrefix('selected', options[i].toLowerCase() + " white", 24);
			menuItem.animation.play('idle');
			menuItems.add(menuItem);
			var scr:Float = (options.length - 4) * 0.135;
			if (options.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
			menuItem.screenCenter(X);
			menuItem.x += 50;
		}

		optionThingy = new FlxSprite(50, 0);
		optionThingy.frames = (Paths.getSparrowAtlas("optionsmenu/options_title"));
        optionThingy.animation.addByPrefix("idle", "options_title", 24, true);
        optionThingy.animation.play("idle");
        add(optionThingy);

		bf = new FlxSprite(50, 0);
        bf.frames = (Paths.getSparrowAtlas("optionsmenu/options_bf"));
        bf.animation.addByPrefix("menu bf", "options_bf", 24, true);
        bf.animation.play("menu bf");
        add(bf);

		toolBox = new FlxSprite(0, 0).loadGraphic(Paths.image('optionsmenu/ToolBox'));
		toolBox.x = FlxG.width - toolBox.width;
        add(toolBox);

		// for (num => option in options)
		// {
		// 	var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option), true);
		// 	optionText.screenCenter();
		// 	optionText.y += (92 * (num - (options.length / 2))) + 45;
		// 	optionText.cameras = [funnyCam];
		// 	grpOptions.add(optionText);
		// }

		changeSelection();
		ClientPrefs.saveSettings();

		#if (target.threaded)
		Thread.create(()->{
			mutex.acquire();

			for (music in VisualsSettingsSubState.pauseMusics)
			{
				if (music.toLowerCase() != "none")
					Paths.music(Paths.formatToSongPath(music));
			}

			mutex.release();
		});
		#end

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('UP_DOWN', 'A_B');
		#end
		
		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		controls.isInSubstate = false;
		persistentUpdate = funnyCam.visible = true;
		
		#if TOUCH_CONTROLS_ALLOWED
		removeTouchPad();
		addTouchPad('UP_DOWN', 'A_B');
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		var lerpVal:Float = Math.max(0, Math.min(1, elapsed * 7.5));
		//camFollowPos.setPosition(635, FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		var bullShit:Int = 0;

		// for (item in grpOptions.members)
		// {
		// 	item.targetY = bullShit - curSelected;
		// 	bullShit++;

		// 	var thing:Float = 0;
		// 	if (item.targetY == 0) {
		// 		if(grpOptions.members.length > 6) {
		// 			thing = grpOptions.members.length * 2;
		// 		}
		// 		camFollow.setPosition(635, item.y + 100 - thing);
		// 	}
		// }

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		menuItems.members[curSelected].animation.play('idle');
		menuItems.members[curSelected].updateHitbox();
		//menuItems.members[curSelected].screenCenter(X);

		curSelected += change;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.members[curSelected].animation.play('selected');
		menuItems.members[curSelected].centerOffsets();
		//menuItems.members[curSelected].screenCenter(X);

		camFollow.setPosition(menuItems.members[curSelected].getGraphicMidpoint().x,
			menuItems.members[curSelected].getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}