package tests.pathbuilding
{
	import alternativa.a3d.collisions.CollisionBoundNode;
	import alternativa.a3d.controller.SimpleFlyController;
	import alternativa.a3d.controller.ThirdPersonController;
	import alternativa.a3d.systems.text.FontSettings;
	import alternativa.a3d.systems.text.StringLog;
	import alternativa.a3d.systems.text.TextMessageSystem;
	import alternativa.a3d.systems.text.TextSpawner;
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.objects.Hud2D;
	import alternativa.engine3d.objects.Sprite3D;
	import alternativa.engine3d.RenderingSystem;
	import alternativa.engine3d.spriteset.materials.MaskColorAtlasMaterial;
	import alternativa.engine3d.spriteset.materials.SpriteSheet8AnimMaterial;
	import alternativa.engine3d.spriteset.materials.TextureAtlasMaterial;
	import alternativa.engine3d.spriteset.SpriteSet;
	import alternativa.engine3d.Template;
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.tick.FrameTickProvider;
	import assets.fonts.ConsoleFont;
	import com.bit101.components.ComboBox;
	import components.Pos;
	import de.polygonal.motor.geom.primitive.AABB2;
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.ui.Keyboard;
	import input.KeyPoll;
	import saboteur.spawners.JettySpawner;
	import saboteur.spawners.SaboteurHud;
	import saboteur.systems.PathBuilderSystem;
	import saboteur.util.GameBuilder3D;
	import saboteur.util.SaboteurPathUtil;
	import spawners.arena.GladiatorBundle;
	import systems.collisions.EllipsoidCollider;
	import systems.collisions.GroundPlaneCollisionSystem;
	import systems.SystemPriorities;
	import util.SpawnerBundle;
	import util.SpawnerBundleLoader;
	import views.engine3d.MainView3D;
	import views.ui.bit101.BuildStepper;
	import views.ui.bit101.PreloaderBar;
	import views.ui.indicators.CanBuildIndicator;
	import views.ui.UISpriteLayer;
	/**
	 * Third person view and Spectator ghost flyer switching with wall collision against builded paths
	 * @author Glenn Ko
	 */
	public class TestPathBuilding3rdPerson extends MovieClip
	{
		//public var engine:Engine;
		public var ticker:FrameTickProvider;
		public var game:TheGame;
		static public const START_PLAYER_Z:Number = 134;
		
		private var _template3D:MainView3D;
		
		private var uiLayer:UISpriteLayer = new UISpriteLayer();
		private var stepper:BuildStepper;
		private var thirdPerson:ThirdPersonController;
		
		private var bundleLoader:SpawnerBundleLoader;
		private var gladiatorBundle:GladiatorBundle;
		private var jettySpawner:JettySpawner;
		private var arenaSpawner:ArenaSpawner;
		private var _preloader:PreloaderBar = new PreloaderBar();
		
		private var spectatorPerson:SimpleFlyController;

		
		public function TestPathBuilding3rdPerson() 
		{
			haxe.initSwc(this);
			addChild(_preloader);
			
			game = new TheGame(stage);
	
			addChild( _template3D = new MainView3D() );
			_template3D.onViewCreate.add(onReady3D);
			addChild(uiLayer);
				
			
			_template3D.visible = false;
		}
		
		
		
		
		private function onReady3D():void 
		{
			
			
			SpawnerBundle.context3D = _template3D.stage3D.context3D;
			
			gladiatorBundle = new GladiatorBundle(arenaSpawner = new ArenaSpawner(game.engine, game.keyPoll));
			jettySpawner = new JettySpawner();
			hudAssets = new SaboteurHud(game.engine, stage, game.keyPoll);
			bundleLoader = new SpawnerBundleLoader(stage, onSpawnerBundleLoaded, new <SpawnerBundle>[gladiatorBundle, jettySpawner, hudAssets]);
			bundleLoader.progressSignal.add( _preloader.setProgress );
			bundleLoader.loadBeginSignal.add( _preloader.setLabel );
		}
		
		private function onSpawnerBundleLoaded():void 
		{
		//		game.gameStates.engineState.changeState("thirdPerson");
				
			_template3D.visible = true;
			removeChild(_preloader);			
			game.engine.addSystem( new RenderingSystem(_template3D.scene), SystemPriorities.render );
			

			
		
			gladiatorBundle.arenaSpawner.addGladiator(ArenaSpawner.RACE_SAMNIAN, stage, 0, 0, START_PLAYER_Z + 33).add( game.keyPoll );
		
		
			
			
			var pathBuilder:PathBuilderSystem = new PathBuilderSystem(_template3D.camera);
			 
			game.gameStates.thirdPerson.addInstance(pathBuilder).withPriority(SystemPriorities.postRender);
			//game.engine.addSystem(pathBuilder, SystemPriorities.postRender );
			pathBuilder.signalBuildableChange.add( onBuildStateChange);
			var canBuildIndicator:CanBuildIndicator = new CanBuildIndicator();
			addChild(canBuildIndicator);
			pathBuilder.onEndPointStateChange.add(canBuildIndicator.setCanBuild);
			
			
	
			
			var ent:Entity = jettySpawner.spawn(game.engine,_template3D.scene, arenaSpawner.currentPlayerEntity.get(Pos) as Pos);


			if (game.colliderSystem) {
				
				game.colliderSystem.collidable = (ent.get(GameBuilder3D) as GameBuilder3D).collisionGraph;
				game.colliderSystem._collider.threshold = 0.0001;
			}
			
			spectatorPerson =new SimpleFlyController( 
						new EllipsoidCollider(GameSettings.SPECTATOR_RADIUS.x, GameSettings.SPECTATOR_RADIUS.y, GameSettings.SPECTATOR_RADIUS.z), 
						(ent.get(GameBuilder3D) as GameBuilder3D).collisionGraph ,
						stage, 
						_template3D.camera, 
						60*512/60/60, //GameSettings.SPECTATOR_SPEED,
						GameSettings.SPECTATOR_SPEED_SHIFT_MULT);
			
						game.gameStates.spectator.addInstance(spectatorPerson).withPriority(SystemPriorities.postRender);
		
	
			thirdPerson = new ThirdPersonController(stage, _template3D.camera, new Object3D(), arenaSpawner.currentPlayer, arenaSpawner.currentPlayer, arenaSpawner.currentPlayerEntity);
			//game.engine.addSystem( thirdPerson, SystemPriorities.postRender ) ;
			game.gameStates.thirdPerson.addInstance(thirdPerson).withPriority(SystemPriorities.postRender);
			
		
			game.engine.addSystem(new TextMessageSystem(), SystemPriorities.render );
			game.gameStates.thirdPerson.addInstance( new GroundPlaneCollisionSystem(122, true) ).withPriority(SystemPriorities.resolveCollisions);
			
			game.gameStates.engineState.changeState("thirdPerson");
		
			
			
			uiLayer.addChild( stepper = new BuildStepper());
			stepper.onBuild.add(pathBuilder.attemptBuild);
			stepper.onStep.add(pathBuilder.setBuildIndex);
			stepper.onDelete.add(pathBuilder.attemptDel);
			
			ticker = new FrameTickProvider(stage);
			ticker.add(tick);
			ticker.start();
			
			var hud:Hud2D;
			//_template3D.camera.orthographic = true;
			_template3D.camera.addChild( hud = new Hud2D() );
			hud.z = 1.1;
			var spr:Sprite3D = new Sprite3D(16, 16, new FillMaterial(0xFF0000, 1));
			spr.x -= 8;
		//	spr.mouseEnabled = false;
		//	spr.mouseChildren = false;
			//spr.perspectiveScale = false;
		//	spr.alwaysOnTop = true;
			spr.useHandCursor = true;
			spr.z = 0;
			
			var spr2:Sprite3D = new Sprite3D(32, 32, new FillMaterial(0x00FF00, 1));
			spr2.useHandCursor = true;
			spr2.z = 1;
			
			_template3D.viewBackgroundColor = 0xDDDDDD;
			
			var font:ConsoleFont = new ConsoleFont();
			var atlasMaterial:MaskColorAtlasMaterial = new MaskColorAtlasMaterial(font.bmpResource, null);
			atlasMaterial.flags = (MaskColorAtlasMaterial.FLAG_MIPNONE | MaskColorAtlasMaterial.FLAG_PIXEL_NEAREST);
			atlasMaterial.alphaThreshold = .99;
		//	atlasMaterial.opaquePass
	//	addChild( new Bitmap(font.bmpResource.data));
		var useRegisters:int = 120;// 116;
		var numRegisters:int = 3;
			spriteSet = new SpriteSet(233, true, atlasMaterial, font.sheet.width, font.sheet.height, useRegisters/numRegisters,numRegisters)
		//	spriteSet.randomisePositions(0, 1|2, stage.stageHeight*.5);
			spriteSet.alwaysOnTop = true;
			spriteSet.useHandCursor = true;
			spriteSet.mouseEnabled = true;
			
			//spriteSet.mouseChildren = true;
			//spriteSet.mouseHandlingType = MouseEvent3D.
			
			var rect:Rectangle = new Rectangle();
			var data:Vector.<Number> = spriteSet.spriteData;
		//	var previewFontSpr:Sprite = new Sprite();
		//	addChild(previewFontSpr);
			//previewFontSpr.graphics.lineStyle(0, 0xFF0000);
		
		
			
			
			hudAssets.addToHud3D(hud);
			spriteSet = hudAssets.txt_chat.spriteSet;
			hudAssets.txt_chatChannel.onContentHeightChange.add(onChayHeightChange);
			
			/*
			hudAssets.writeChatText("1. hello i am Glenn!!!");
			hudAssets.writeChatText("2. helwarwar awaw rara uraruhawriah iruawrui awiraw raiur uaiwruiawr awrawawrawrwaaw wawa wawawa aw rwa warwat awtwat awtwa twat watwa twat awtwatwatawrlo i am Glenn!!!");
			*/
			hudAssets.txt_chatChannel.timeout = -1;
		//	hudAssets.txt_chatChannel.setMaxDisplayedItemsTruncate(15);
		//	hudAssets.txt_chatChannel.setShowItems(5);
			//hudAssets.txt_chatChannel.enableMarquee = true;
			hudAssets.txt_chatChannel.history = new StringLog();
			hudAssets.txt_chatChannel.appendSpanTagMessage('The quick brown <span u="2">fox</span> jumps over the lazy dog. The <span u="1">quick brown fox</span> jumps over the lazy <span u="3">dog</span>. The <span u="1">quick brown fox</span> jumps over the lazy dog.');
			//hud.addChild(spr);
			//hud.addChild(spr2);
			//hud.addChild(spriteSet);
			//previewFontSpr.addChild( new Bitmap(font.sheet));
			
			
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false,1);
		
		}
		
		private function onChayHeightChange(height:Number, cropped:Boolean):void {
			spriteSet.y = height;
			

		}
		
		
		
		private function trim( s:String ):String
{
  return s.replace( /^([\s|\t|\n]+)?(.*)([\s|\t|\n]+)?$/gm, "" );
}
		
		
		
		private var _isThirdPerson:Boolean = true;
		private var spriteSet:SpriteSet;
		private var hudAssets:SaboteurHud;
		private function onKeyDown(e:KeyboardEvent):void 
		{
			if (!game.keyPoll.disabled) {
				if (e.keyCode === Keyboard.L &&   !game.keyPoll.isDown(Keyboard.L)) { // && 
					
					_isThirdPerson = !_isThirdPerson;
					game.gameStates.engineState.changeState(_isThirdPerson ? "thirdPerson" : "spectator");
					
				}
				
				if (e.keyCode === Keyboard.U &&   !game.keyPoll.isDown(Keyboard.U)) { // && 
					
					if (	hudAssets.txt_chatChannel.getShowItems() == 5) {
						hudAssets.txt_chatChannel.setShowItems(12);
					}
					else hudAssets.txt_chatChannel.setShowItems(5);
				
				}
				
				if (e.keyCode === Keyboard.PAGE_UP &&   !game.keyPoll.isDown(Keyboard.PAGE_UP) ) {
					hudAssets.txt_chatChannel.scrollUpHistory();
				}
				else if (e.keyCode === Keyboard.PAGE_DOWN &&   !game.keyPoll.isDown(Keyboard.PAGE_DOWN)) {
					hudAssets.txt_chatChannel.scrollDownHistory();
				}
				else if  (e.keyCode === Keyboard.END &&   !game.keyPoll.isDown(Keyboard.END)) {
					hudAssets.txt_chatChannel.scrollEndHistory();
				}
				
				if (e.keyCode === Keyboard.BACKSLASH &&   !game.keyPoll.isDown(Keyboard.BACKSLASH)) { // && 
					hudAssets.txt_chatChannel.resetAllScrollingMessages();
					/*
					if (	hudAssets.txt_chatChannel.getShowItems() == 5) {
						hudAssets.txt_chatChannel.setShowItems(12);
					}
					else hudAssets.txt_chatChannel.setShowItems(5);
				*/
				}
			}
			if (e.keyCode === Keyboard.F11) {
				System.pauseForGCIfCollectionImminent();
				
			}
		}
		
	
		
		private function tick(time:Number):void {
			game.engine.update(time);
			_template3D.render();
		}
		
		private function onBuildStateChange(result:int):void 
		{
			stepper.buildBtn.enabled = result === SaboteurPathUtil.RESULT_VALID;
			stepper.delBtn.enabled = result === SaboteurPathUtil.RESULT_OCCUPIED;
		}
		
		
		
	}

}