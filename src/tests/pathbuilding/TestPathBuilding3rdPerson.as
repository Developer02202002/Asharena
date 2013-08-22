package tests.pathbuilding
{
	import alternativa.a3d.collisions.CollisionBoundNode;
	import alternativa.a3d.controller.SimpleFlyController;
	import alternativa.a3d.controller.ThirdPersonController;
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.objects.Hud2D;
	import alternativa.engine3d.objects.Sprite3D;
	import alternativa.engine3d.RenderingSystem;
	import alternativa.engine3d.spriteset.materials.TextureAtlasMaterial;
	import alternativa.engine3d.spriteset.SpriteSet;
	import alternativa.engine3d.Template;
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.tick.FrameTickProvider;
	import assets.fonts.ConsoleFont;
	import com.bit101.components.ComboBox;
	import components.Pos;
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import input.KeyPoll;
	import saboteur.spawners.JettySpawner;
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
			
			gladiatorBundle = new GladiatorBundle(arenaSpawner = new ArenaSpawner(game.engine));
			jettySpawner = new JettySpawner();
				
			bundleLoader = new SpawnerBundleLoader(stage, onSpawnerBundleLoaded, new <SpawnerBundle>[gladiatorBundle, jettySpawner]);
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
						GameSettings.SPECTATOR_SPEED,
						GameSettings.SPECTATOR_SPEED_SHIFT_MULT);
			
						game.gameStates.spectator.addInstance(spectatorPerson).withPriority(SystemPriorities.postRender);
		
	
			thirdPerson = new ThirdPersonController(stage, _template3D.camera, new Object3D(), arenaSpawner.currentPlayer, arenaSpawner.currentPlayer, arenaSpawner.currentPlayerEntity);
			//game.engine.addSystem( thirdPerson, SystemPriorities.postRender ) ;
			game.gameStates.thirdPerson.addInstance(thirdPerson).withPriority(SystemPriorities.postRender);
			
		
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
			
			_template3D.viewBackgroundColor = 0xFFFFFF;
			
			var font:ConsoleFont = new ConsoleFont();
			var atlasMaterial:TextureAtlasMaterial = new TextureAtlasMaterial(font.bmpResource, null);
			atlasMaterial.alphaThreshold = .99;
		//	atlasMaterial.opaquePass
		//addChild( new Bitmap(font.bmpResource.data));
			var spriteSet:SpriteSet = new SpriteSet(233, true, atlasMaterial, font.sheet.width, font.sheet.height, 60,2)
			spriteSet.randomisePositions(0, 1|2, stage.stageHeight*.5);
			//spriteSet.alwaysOnTop = true;
			
			
			var rect:Rectangle = new Rectangle();
			var data:Vector.<Number> = spriteSet.spriteData;
			var previewFontSpr:Sprite = new Sprite();
			addChild(previewFontSpr);
			previewFontSpr.graphics.lineStyle(0, 0xFF0000);
			
			for (var i:int = 0; i < data.length; i += 8) {
				font.getRandomRect(rect);
				data[i + 4] =  rect.x;
				data[i + 5] = 1-rect.y - rect.height;
				data[i + 6] =   rect.width;
				data[i + 7] =  rect.height;
				previewFontSpr.graphics.drawRect(rect.x*font.sheet.width, rect.y*font.sheet.height, rect.width*font.sheet.width, rect.height*font.sheet.height);
				//if (rect.x > 1 || rect.y > 1 || rect.width > 1 || rect.height > 1 || rect.x < 0 || rect.y < 0 || rect.width < 0 || rect.height < 0) throw new Error("OUTTA BOUNDS:" +rect);
			}
			
			//hud.addChild(spr);
			//hud.addChild(spr2);
			hud.addChild(spriteSet);
			previewFontSpr.addChild( new Bitmap(font.sheet));
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
		}
		
		
		
		private var _isThirdPerson:Boolean = true;
		private function onKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode === Keyboard.L) {
				
				_isThirdPerson = !_isThirdPerson;
				game.gameStates.engineState.changeState(_isThirdPerson ? "thirdPerson" : "spectator");
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