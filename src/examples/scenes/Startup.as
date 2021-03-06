package examples.scenes
{
	import de.popforge.revive.application.SceneContainer;
	import de.popforge.revive.display.IDrawAble;
	import de.popforge.revive.forces.*;
	import de.popforge.revive.geom.Vec2D;
	import de.popforge.revive.member.*;
	import de.popforge.revive.resolve.DynamicIntersection;
	import de.popforge.revive.resolve.IDynamicIntersectionTestAble;
	import de.popforge.surface.io.PopKeys;
	import examples.scenes.test.MovableChar;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;

	/*  
		2D Party/squad formation utility control gizmo
	*/
			
	public class Startup extends SceneContainer
	{
		
		private var personA:Person = new Person(MovableChar.COLORS[0], "leader", SMALL_RADIUS);
		private var personB:Person = new Person(MovableChar.COLORS[1], "person b", SMALL_RADIUS);	
		private var personC:Person = new Person(MovableChar.COLORS[2], "person c", SMALL_RADIUS)
		private var personD:Person = new Person(MovableChar.COLORS[3], "person d", SMALL_RADIUS);

		
		private var footing:int = new Vector.<int>(3, true);
		
		
		// Formation fill-order schemes:
		// FORMATION_DIAMOND_WEDGE :: Diamond (n mid determined per add), Frontal Wedge, Filled Wedge (Delta)
		// FORMATION_FILE :: Column-Snake, Column-Straight, Line, Phalanx-Balanced(n front), Phalanx-Left(n front), Phalanx-Right(n front)
		// FORMATION_VEE :: Frontal Vee (Inverse frontal wedge), Filled Vee (Cone/Inverse-Delta)
		
		// Formation projection shape schemes
		public static const FORMATION_DIAMOND_WEDGE:int = 0;
		public static const FORMATION_FILE:int = 1;
		public static const FORMATION_VEE:int = 2;
		public var formationShape:int = FORMATION_DIAMOND_WEDGE;  
		public var columnMembers:Vector.<Number> = new Vector.<Number>();  // for >4 members
		public var columnMemberPositions:Vector.<Number> = new Vector.<Number>();
		public var columnBias:Boolean = false;  // whether formation should be biased to conforming to fall-back column vs conforming to actual formation positions


		
		
		public function Startup()
		{
			super();
			simulation.globalDrag = 1;
			simulation.globalForce = new Vec2D(0, 0);
			
			if (stage)  createScene();
			createParty();
			
			if (stage)  createStageBounds();
			if (stage)  drawImmovables();
			
			if (stage) {
				addChild(personA);
				addChild(personB);
				addChild(personC);
				addChild(personD);
			}
			
			if (stage) {
				stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				PopKeys.initStage(stage);
			}
		}
		
	
		
		
		public function manualInit():void {
			removeEventListener( Event.ADDED, onAdded );
			removeEventListener( Event.REMOVED, onRemoved );
		}
		
		public function manualInit2DPreview(cont:Sprite):void {
			//removeEventListener( Event.ADDED, onAdded );
			//removeEventListener( Event.REMOVED, onRemoved );
			
			cont.addChild(this);
			addChild(personA);
			addChild(personB);
			addChild(personC);
			addChild(personD);
	
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		
		public function stickCloseFormation():void {
			targetSpringRest =  LARGE_RADIUS  + 1;
		}
		
		public function spreadOutFormation():void {
			targetSpringRest =  LARGE_RADIUS * 2 + 1;
		}
		
		private function createParty(spreadSetting:int=1):void 
		{
			var pos:Array = POSITIONS_COLUMN_JITTERD;
			
			var mainhead:Number = LARGE_RADIUS ;
			movableA = new MovableChar( pos[0].x, pos[0].y, SMALL_RADIUS, 0 );
			
			simulation.addMovable( movableA );
			movableB = new MovableChar( pos[1].x, pos[1].y, SMALL_RADIUS , 1 );
			simulation.addMovable( movableB );
			movableC = new MovableChar( pos[2].x, pos[2].y, SMALL_RADIUS, 2 );
			simulation.addMovable( movableC );
			movableD = new MovableChar( pos[3].x, pos[3].y, SMALL_RADIUS, 3 );
			simulation.addMovable( movableD );
			
			personA.x = movableA.x; personA.y = movableA.y;
			personB.x = movableB.x; personB.y = movableB.y;
			personC.x = movableC.x; personC.y = movableC.y;
			personD.x = movableD.x; personD.y = movableD.y;
	
			memberCircleLookup.push(movableB);
			memberCircleLookup.push(movableC);
			memberCircleLookup.push(movableD);
					
			memberCharLookup.push(personB);
			memberCharLookup.push(personC);
			memberCharLookup.push(personD);
			
			footsteps.push(movableA.x);
			footsteps.push(movableA.y);
			
			if (stage) simulation.addForce(new ArrowKeys(movableA));
			
			var force: IForce;
			var tension:Number =1;
			
			setSpreadMode(spreadSetting);
			var restLength:Number = targetSpringRest;// -1;// mainhead * 2 + 1;
			
			if (!FOLLOW_LEADER_SPRING) {
				force = new Spring( movableA, movableB, tension);
				simulation.addForce( force );
				springs.push(force);
				
				force = new Spring( movableB, movableC, tension);
				simulation.addForce( force );
				springs.push(force);
				
				force = new Spring( movableC, movableD, tension);
				simulation.addForce( force );
				springs.push(force);
			}
			else {
			
				
				force = new FixedSpring( movableA.x, movableA.y, movableB, tension);
				simulation.addForce( force );
				springs.push(force);
				fixedSprings.push(force);
				
				force = new FixedSpring( movableA.x, movableA.y, movableC, tension);
				simulation.addForce( force );
				springs.push(force);
				fixedSprings.push(force);
				
				force = new FixedSpring( movableA.x, movableA.y, movableD, tension );
				simulation.addForce( force );
				springs.push(force);
				fixedSprings.push(force);
				
				
				
				/*
				force = new Spring( movableB, movableC, tension);
				simulation.addForce( force );
				
				force = new Spring( movableD, movableB, tension);
				simulation.addForce( force );
				
				force = new Spring( movableD, movableC, tension);
				simulation.addForce( force );
				*/
				
			}
			
			//simulation.addMovable( new MovableCircle(13, 13, 4) );
			//simulation.addMovable( new MovableCircle(13, 23, 4) );
			
		}
		
		private function onKeyDown(e:KeyboardEvent):void 
		{
			var kc:uint = e.keyCode;
			
			if (kc === Keyboard.P) {  // test person BCD spread out
				var spr:Spring;
				springs.push(spr = new Spring(movableB, movableD, 1) );
				simulation.addForce(spr);
				springs.push(spr = new Spring(movableC, movableD, 1) );
				simulation.addForce(spr);
			}
			
		}
		public static var START_X:Number = 256;
		public static var START_Y:Number = 96;
		
		private var POSITIONS_COLUMN:Array = [ 
			new Point(START_X, START_Y),
			new Point(START_X, START_Y+LARGE_RADIUS*1),
			new Point(START_X, START_Y+LARGE_RADIUS*2),
			new Point(START_X, START_Y+LARGE_RADIUS*3) 
		];
		
		private var POSITIONS_COLUMN_STAGGERED:Array = [ 
			new Point(START_X+16, START_Y),
			new Point(START_X-16, START_Y+LARGE_RADIUS*1),
			new Point(START_X+16, START_Y+LARGE_RADIUS*2),
			new Point(START_X-16, START_Y+LARGE_RADIUS*3) 
		];
		private var POSITIONS_COLUMN_JITTERD:Array = [ 
			new Point(START_X+4, START_Y),
			new Point(START_X-4, START_Y+LARGE_RADIUS*1),
			new Point(START_X+4, START_Y+LARGE_RADIUS*2),
			new Point(START_X-4, START_Y+LARGE_RADIUS*3) 
		];
		
		
		private var POSITIONS_WEDGE:Array = [ 
			new Point(START_X, START_Y),
			new Point(START_X-32, START_Y+32),
			new Point(START_X+32, START_Y+32),
			new Point(START_X, START_Y+64) 
		];
		
		
		
		private static var FOLLOW_LEADER_SPRING:Boolean = true;
		public var movableA:MovableChar;
		public var movableB:MovableChar;
		public var movableC:MovableChar;
		public var movableD:MovableChar;
		
		
		private var testCircle:MovableCircle = new MovableCircle(0, 0, 3);
		
		private var invalidMembers:Vector.<int> = new Vector.<int>();
		private var validMembers:Vector.<int> =  new Vector.<int>();
		public var memberCircleLookup:Vector.<MovableChar> = new Vector.<MovableChar>();
		private var memberCharLookup:Vector.<Person> = new Vector.<Person>();
		
		private var fixedSprings:Array = [];
		
		private function switchSpring(index:int, force:IForce):* {
			if (springs[index] === force) return;
			simulation.removeForce(springs[index]);
			simulation.addForce(force);
			springs[index] = force;
			var forcer:Object = (force as Object);
			forcer.autoSetRestLength();
			//if (forcer.restLength != (forcer.targetLength >= 0 ? forcer.targetLength : for
			return force;
		}
		
		
	
		
		
	
		private var freqFootsteps:int = 0;
		public var footsteps:Vector.<Number> = new Vector.<Number>();
	
		
		public function tick():void {
			onEnterFrame(null);
		}
		
		private static const DUMMY_EVENT:Event = new Event("enterFrame");
		public function tickPreview():void {
			onEnterFrame(DUMMY_EVENT);
		}
		
		override protected function onEnterFrame( event: Event ): void
		{
			var i:int;
			
			// for any small radius person following the leader, check if can expand radius out and still fit within environment. Does expanding radius out collide with other players from B,C,D? If so, add temporary spring out links between them.
			
			var numValid:int = 0;
			var numInvalid:int = 0;
			

			
			
			if (enableFootsteps) {
				if (footsteps.length == 0) {
					footsteps[0] = movableA.x;
					footsteps[1] = movableA.y;
				}
				var lastX:Number = footsteps[footsteps.length - 2];
				var lastY:Number = footsteps[footsteps.length - 1];
				lastX  = movableA.x - lastX;
				lastY  = movableA.y - lastY;
				lastX *= lastX;
				lastY *= lastY;
				if (lastX + lastY > footStepThreshold) {
					footsteps.push(movableA.x);
					footsteps.push(movableA.y);
					if (footStepCallback!=null) footStepCallback();
				}
				
			}

			
			// check valid links
			//for each(var obstacle:IDynamicIntersectionTestAble in simulation.immovables) {
				if ( checkLinkToLeaderBlocked( movableB, personB, movableB.r ) ) {
					if (movableB.r != SMALL_RADIUS) {
						movableB.r = SMALL_RADIUS;
						if (checkLinkToLeaderBlocked( movableB, personB, SMALL_RADIUS-4)) {
							// add to invalid
							invalidMembers[numInvalid++] = 0; 
						}
						else {
							// add to valid
							validMembers[numValid++] = 0;
							movableB.following = 0;
							switchSpring(0, fixedSprings[0]);
							
						}
					}
					else { // add to invalid
						
						
						invalidMembers[numInvalid++] = 0; 

					}
				}
				else {
							// add to valid
						movableB.following = 0;
						validMembers[numValid++] = 0;
						switchSpring(0, fixedSprings[0]);
							
				}
						
				if ( checkLinkToLeaderBlocked( movableC, personC,  movableC.r  ) ) {
					if (movableC.r != SMALL_RADIUS) {
						movableC.r = SMALL_RADIUS;
						if (checkLinkToLeaderBlocked( movableC, personC, SMALL_RADIUS-4)) {
							// add to invalid
							invalidMembers[numInvalid++] = 1; //throw new Error("C");
						}
						else {
							// add to valid
							validMembers[numValid++] = 1;
							movableC.following = 0;
							switchSpring(1, fixedSprings[1]);
						}
					}
					else { // add to invalid
						
						
						invalidMembers[numInvalid++] = 1; 

					}
				}
				else {
							// add to valid
							movableC.following = 0;
					validMembers[numValid++] = 1;
						switchSpring(1, fixedSprings[1]);
							
				}
				
				if ( checkLinkToLeaderBlocked( movableD, personD,  movableD.r  ) ) {
					if (movableD.r != SMALL_RADIUS) {
						movableD.r = SMALL_RADIUS;
						if ( checkLinkToLeaderBlocked( movableD, personD, SMALL_RADIUS-4)) {
							// add to invalid
							invalidMembers[numInvalid++] = 2;// throw new Error("D");
							
						}
						else {
							// add to valid
							movableD.following = 0;
							validMembers[numValid++] = 2;
							switchSpring(2, fixedSprings[2]);
						}
					}
					else{ // add to invalid
						invalidMembers[numInvalid++] = 2; 

					}
				}
				else {
					// add to valid
					validMembers[numValid++] = 2;
					movableD.following = 0;
					switchSpring(2, fixedSprings[2]);
							//throw new Error("A");
				}
			//}
			
			var initialValidMembers:int = numValid;
			
			
			var index:int;
			var u:int;
			for (i = 0; i < numInvalid; i++) {
				
				index = invalidMembers[i];
				u = numValid;
				var resolved:Boolean = false;
				while (--u > -1) {
					if ( checkLinkToLeaderBlocked(memberCircleLookup[index], memberCharLookup[index], SMALL_RADIUS, memberCircleLookup[validMembers[u]] ) ) {
						
						
					}
					else {
						validMembers[numValid++] = index;
						
						switchSpring(index, new Spring(memberCircleLookup[index], memberCircleLookup[validMembers[u]], 1) );
						memberCircleLookup[index].following =1;
						resolved = true;
						break;
					}
				}
				
				
				if (!resolved) {
				//	simulation.removeForce(springs[index]);
					//springs[index] = NULL_SPRING;
					memberCircleLookup[index].following = -1;
					
					var f:int = footsteps.length;
					f -= 2;
					while (f >= 0) {
						
						testLeader.x =  footsteps[f];
						testLeader.y = footsteps[f + 1];
						if (!checkLinkToLeaderBlocked(memberCircleLookup[index], memberCharLookup[index], SMALL_RADIUS-2, testLeader) ) {
							switchSpring(index, new FixedSpring(testLeader.x, testLeader.y, memberCircleLookup[index], 1) );
							
							springs[index].targetLength = 0.1;
							resolved = true;
							break;
						}
						f -= 2;
					}
					
					if (!resolved) {
						switchSpring(index, NULL_SPRING);
						memberCircleLookup[index].following = -2;
					}
					
					
					/*
					if (numValid > 0) {

						springs[index] = new Spring(memberCircleLookup[index], memberCircleLookup[validMembers[numValid-1]], 1);
						simulation.addForce(springs[index]);
							validMembers[numValid++] = index;
						resolved = true;
					}
					else {
						
					
						switchSpring( 0, new Spring( movableA, movableB, 1) );
						switchSpring( 1, new Spring( movableB, movableC, 1) );
						switchSpring( 2, new Spring( movableC, movableD, 1) );
						
						
						//simulation.removeForce(springs[index]);
						
						
						
						
					}
					*/
					
						
				}
				
				
				
			}
			
			
			
			
			
	
			
			i = springs.length;
			while (--i > -1) {
				transitSpringLength(springs[i], targetSpringRest);
				
			}
		
			super.onEnterFrame(event);
		//	if (movableA.velocity.length() ) throw new Error(movableA.velocity);
			/*
			mShape.graphics.beginFill(0xFF0000, 1);
			var len:int = footsteps.length;
			for (var p:int = 0; p < len; p+=2 ) 
			{
				//drawAble.draw( mShape.graphics );
				mShape.graphics.drawCircle( footsteps[p], footsteps[p + 1], 2);
			}
			*/
			
			i = fixedSprings.length;
				while (--i > -1) {
					
						
						fixedSprings[i].x = movableA.x;
						fixedSprings[i].y = movableA.y;
					
					
				}
				
				var lastForwardW:Number = forwardVector.w;
				
				
					// now, determine pos standing offsets for memberCircles, based off current formation links
					f = 0;
					f +=movableB.following < 0 ? 0 : movableB.following;
					f +=  movableC.following < 0 ? 0 : movableC.following;
					f += movableD.following < 0 ? 0 : movableD.following;
					
		
					movableB.slot = -1;
					movableC.slot = -1;
					movableD.slot = -1;
					movableB.offsetX = 0; movableB.offsetY = 0;
					movableC.offsetX = 0; movableC.offsetY = 0;
					movableD.offsetX = 0; movableD.offsetY = 0;
		
					if (f==0) {  // all following leader
						// possible triangle formation, resolve to diamond if required
						_formationState = 0;
						resolveTriFormation();
						
					}
					else if ( f === 1) {  // 2 follwong leader, only 1 following someone
						_formationState = 1;
						// determine rearguard only
						rearGuard = (movableD.following > 0  ? movableD : movableC.following > 0 ? movableC : movableB)
						lastRearGuardSlot = rearGuard.slot;
						rearGuard.slot = 2;
						
						forwardVector.x = movableA.x - rearGuard.x;
						forwardVector.y = movableA.y - rearGuard.y;
						forwardVector.normalize();
						forwardVector.w = 0;
						
					}
					else if ( f == 2) {  // a column is used, determine rearguard only
						_formationState = 2;
						
						rearGuard = (movableD.following > 0 && memberCircleLookup[movableD.following].following > 0 ? movableD : movableC.following > 0 &&  memberCircleLookup[movableC.following].following > 0 ? movableC : movableB)
						lastRearGuardSlot = rearGuard.slot;
						rearGuard.slot = 2;
						
						forwardVector.x = movableA.x - rearGuard.x;
						forwardVector.y = movableA.y - rearGuard.y;
						forwardVector.normalize();
						forwardVector.w = 0;
						
					}
				
			// move guys to match formation points
			/*
			personA.x = movableA.x; personA.y = movableA.y;
			personB.moveToTargetLocation(movableB.x, movableB.y);
			personC.moveToTargetLocation(movableC.x, movableC.y);
			personD.moveToTargetLocation(movableD.x, movableD.y);
			*/
			//
			
			
			if (forwardVector.w == 0) {
				mShape.graphics.lineStyle(1, 0xFF0000, 1);
				mShape.graphics.moveTo(movableA.x, movableA.y);
				mShape.graphics.lineTo(movableA.x + forwardVector.x * 32, movableA.y + forwardVector.y * 32);
				
				/*
				//if (forwardVector.x+movableA
				// TODO: optimize this once done
				lastX = snakeFootsteps[snakeFootsteps.length - 2];
				lastY = snakeFootsteps[snakeFootsteps.length - 1];
				lastX  = movableA.x - lastX;
				lastY  = movableA.y - lastY;
				lastX *= lastX;
				lastY *= lastY;
				
				testVec.x = ( movableA.x - snakeFootsteps[snakeFootsteps.length - 2]) / Math.sqrt(lastX + lastY);
				testVec.y = ( movableA.y - snakeFootsteps[snakeFootsteps.length - 1]) / Math.sqrt(lastX + lastY);
				
				if ( (lastForwardW==-1 || (testVec.dotProduct(forwardVector)) >= .8) && lastX + lastY > footStepThreshold) {
					snakeFootsteps.push(movableA.x);
					snakeFootsteps.push(movableA.y);
				}
				*/
				var snakeFootsteps:Vector.<Number>  = footsteps;
				
				var limit:int = snakeFootsteps.length  - (16)*2;
				if (limit < 1) limit = 1;
				mShape.graphics.lineStyle(undefined, 0, 0);
				mShape.graphics.beginFill(0xFF0000, 1);
				for (i = snakeFootsteps.length - 1; i >= limit;  i-=2) {
					mShape.graphics.drawCircle( snakeFootsteps[i-1], snakeFootsteps[i], .2)
				}
			}
			else {
				
				footsteps.length = 0;
			}
			
			
						
			
			
			// check for temporary BCD springs that can afford to be removed (ie. completed)
		}
		
		
		private var testVec:Vector3D = new Vector3D();
		
		private function resolveTriFormation():void 
		{
			
		
			
			var rearGuard:MovableChar;
			var dx:Number;
			var dy:Number;
			
			var dx2:Number;
			var dy2:Number;
		
			var temp:Number;
			var sign:Number;
			var sign2:Number;
			// find the 2 flankers
			
			var numFlankers:int = 0;
			
			dx=movableA.x - movableB.x;
			dy = movableA.y - movableB.y;
			temp = dx;
			dx = -dy;
			dy = temp;
	
			
			dx2 = movableC.x - movableB.x;
			dy2 = movableC.y - movableB.y;
			sign = dx * dx2 + dy * dy2;
			dx2 = movableD.x - movableB.x;
			dy2 = movableD.y - movableB.y;
			sign2 = dx * dx2 + dy * dy2;
			sign = sign > 0 ? 1 : -1;
			sign2 = sign2 > 0 ? 1 : -1;
			numFlankers += sign === sign2 ? 1 : 0;
			if (sign === sign2) {
				movableB.slot =  sign < 0 ? 1 : 0;
				movableB.offsetX = dx * sign;
				movableB.offsetY = dy * sign;
			}
			
			dx=movableA.x - movableC.x;
			dy=movableA.y - movableC.y;
			temp = dx;
			dx = -dy;
			dy = temp;
			
			dx2 = movableB.x - movableC.x;
			dy2 = movableB.y - movableC.y;
			sign = dx * dx2 + dy * dy2;
			dx2 = movableD.x - movableC.x;
			dy2 = movableD.y - movableC.y;
			sign2 = dx * dx2 + dy * dy2;
			sign = sign > 0 ? 1 : -1;
			sign2 = sign2 > 0 ? 1 : -1;
			numFlankers += sign === sign2 ? 1 : 0;
			if (sign === sign2) {
				movableC.slot =  sign < 0 ? 1 : 0;
				movableC.offsetX = dx * sign;
				movableC.offsetY = dy * sign;
			}
			
			//if (numFlankers !=2) {
				dx=movableA.x - movableD.x;
				dy=movableA.y - movableD.y;
				temp = dx;
				dx = -dy;
				dy = temp;
			
				dx2 = movableC.x - movableD.x;
				dy2 = movableC.y - movableD.y;
				sign = dx * dx2 + dy * dy2;
				dx2 = movableB.x - movableD.x;
				dy2 = movableB.y - movableD.y;
				sign2 = dx * dx2 + dy * dy2;
				sign = sign > 0 ? 1 : -1;
				sign2 = sign2 > 0 ? 1 : -1;
				numFlankers += sign === sign2 ? 1 : 0;
				if (sign === sign2) {
					movableD.slot = sign < 0 ? 1 : 0;
					movableD.offsetX = dx * sign;
					movableD.offsetY = dy * sign;
				}
			//}
			
			if (numFlankers != 2) {  // invalid, so 
				
					movableB.offsetX = 0; movableB.offsetY = 0;
					movableC.offsetX = 0; movableC.offsetY = 0;
					movableD.offsetX = 0; movableD.offsetY = 0;
					movableB.slot = -1;
					movableC.slot = -1;
					movableD.slot = -1;
					//forwardVector.w = -2;
				
				//throw new Error("numflanks:"+numFlankers);
				//if (numFlankers == 0) throw new Error("NO FLANKERS");
				return;
			}
			else if (numFlankers === 3) {
				throw new Error("WEIRD 3 flankers");
			}
			
			//throw new Error("GOT 2 flankers");
			
			// find rearguard among the 2 flankers
			var flanker1:MovableChar;
			var flanker2:MovableChar;
			
			
			
			if (movableD.slot < 0) {
				flanker1 = movableB;
				flanker2 = movableC;
				rearGuard = movableD;
			}
			else if (movableC.slot < 0) {
				flanker1 = movableB;
				flanker2 = movableD;
				rearGuard = movableC;
			}
			else {
				flanker1 = movableD;
				flanker2 = movableC;
				rearGuard = movableB;
			}
			
			
			
			// flankers form an obtuse or right angle that don't need seperation since they are spreaded far enough
			// ( can early exit here)
			if (flanker1.offsetX * flanker2.offsetX + flanker1.offsetY * flanker2.offsetY >= 0) {
					movableB.offsetX = 0; movableB.offsetY = 0;
					movableC.offsetX = 0; movableC.offsetY = 0;
					movableD.offsetX = 0; movableD.offsetY = 0;
					movableB.slot = -1;
					movableC.slot = -1;
					movableD.slot = -1;
					forwardVector.w = -1;
					return;
			}
			
			rearGuard.slot = 2;
			
			/*
			// fix, let flanker wingers always look for nearest circle slot
			dx = memberCharLookup[flanker1.slot].x - flanker1.x;
			dy = memberCharLookup[flanker1.slot].y - flanker1.y;
			dx = dx * dx + dy * dy;
			
			
			dx2 = memberCharLookup[flanker2.slot].x - flanker1.x;
			dy2 = memberCharLookup[flanker2.slot].y - flanker1.y;
			dy = dx2 * dx2 + dy2 * dy2;
			
			if (dx < dy) {
			//	var tempSlot:int = flanker1.slot;
				//flanker1.slot = flanker2.slot;
			//	flanker2.slot = tempSlot;
			}
			*/
			
			// else  flankers form an acute angle that needs some spreading out.
			
			
			
			// move rearguard back
			rearGuard.offsetX = rearGuard.x - movableA.x;
			rearGuard.offsetY = rearGuard.y - movableA.y;
		
			dx = Math.sqrt(rearGuard.offsetX * rearGuard.offsetX + rearGuard.offsetY * rearGuard.offsetY);
			dx = (rearGuard.r  / dx);
			rearGuard.offsetX *= dx;
			rearGuard.offsetY *= dx;
			
			
			
			dx = flanker1.offsetX;
			dy = flanker1.offsetY;
			dx2 = flanker2.offsetX;
			dy2 = flanker2.offsetY;
			
			
			
			flanker1.offsetX =  movableA.x + dx2 - flanker1.x;
			flanker1.offsetY =  movableA.y + dy2 - flanker1.y;
			
			flanker2.offsetX =  movableA.x + dx - flanker2.x;
			flanker2.offsetY =  movableA.y + dy - flanker2.y;
			
		
			flanker1.offsetX *= flanker1.flankScale; flanker1.offsetY *= flanker1.flankScale;
			flanker2.offsetX *= flanker2.flankScale; flanker2.offsetY *= flanker2.flankScale;
			

			var intersect:DynamicIntersection;
		
			testCircle.x = flanker1.x;
			testCircle.y = flanker1.y;
			testCircle.r = flanker1.r;
			testCircle.velocity.x = flanker1.offsetX;
			testCircle.velocity.y = flanker1.offsetY;
			intersect = getClosestIntersectionEnv(testCircle);
			dx = intersect != null ? intersect.dt : 1;
			flanker1.offsetX *= dx;
			flanker1.offsetY *= dx;
			
			testCircle.x = flanker2.x;
			testCircle.y = flanker2.y;
			testCircle.r = flanker2.r;
			testCircle.velocity.x = flanker2.offsetX;
			testCircle.velocity.y = flanker2.offsetY;
			intersect = getClosestIntersectionEnv(testCircle);
			dx = intersect != null ? intersect.dt : 1;
			flanker2.offsetX *= dx;
			flanker2.offsetY *= dx;
			
			if (spreadMode == 0) {
				flanker1.offsetX = movableA.x - flanker1.x;
				flanker1.offsetY = movableA.y - flanker1.y;
				flanker2.offsetX =movableA.x - flanker2.x;
				flanker2.offsetY = movableA.y - flanker2.y;
				
				dx = Math.sqrt(flanker1.offsetX * flanker1.offsetX + flanker1.offsetY * flanker1.offsetY);
				dx = (flanker1.r *1 / dx);
				flanker1.offsetX *= dx;
				flanker1.offsetY *= dx;
				
				dx = Math.sqrt(flanker2.offsetX * flanker2.offsetX + flanker2.offsetY * flanker2.offsetY);
				dx = (flanker2.r *1  / dx);
				flanker2.offsetX *= dx;
				flanker2.offsetY *= dx;
				
				rearGuard.offsetX =0;
				rearGuard.offsetY =0;
				
			}
			
			

			//flanker1.offsetX =0; 	flanker1.offsetY =0;
			//flanker2.offsetX = 0; flanker2.offsetY = 0;
			forwardVector.x = movableA.x - rearGuard.x;
			forwardVector.y = movableA.y - rearGuard.y;
			forwardVector.normalize();
			forwardVector.w = 0;
			
			if (formationShape == FORMATION_FILE) {  // move up flanker offset positions along formation direction
				//temp = forwardVector.x;
				//forwardVector.x = -forwardVector.y;
				//forwardVector.y = temp;
				
				// dotProduct of forward vector over
				dx = movableA.x - flanker1.x - flanker1.offsetX;
				dy = movableA.y - flanker1.y - flanker1.offsetY;
				temp = dx * forwardVector.x + dy * forwardVector.y;
				//dx2 = flanker1.offsetX  * forwardVector.x + flanker1.offsetY * forwardVector.y;
				//temp =temp / dx2;
				flanker1.offsetX += temp * forwardVector.x;
				flanker1.offsetY += temp * forwardVector.y;
				
				
				dx = movableA.x - flanker2.x - flanker2.offsetX;
				dy = movableA.y - flanker2.y - flanker2.offsetY;
				temp = dx * forwardVector.x + dy * forwardVector.y;
				
				flanker2.offsetX += temp * forwardVector.x;
				flanker2.offsetY += temp * forwardVector.y;
				
				rearGuard.offsetX = 0;
				rearGuard.offsetY = 0;
			
			}
			else if (formationShape == FORMATION_VEE) {  // project forward flankers
				dx = movableA.x - flanker1.x - flanker1.offsetX;
				dy = movableA.y - flanker1.y - flanker1.offsetY;
				temp = dx * forwardVector.x + dy * forwardVector.y;
				temp *= 2;
				//dx2 = flanker1.offsetX  * forwardVector.x + flanker1.offsetY * forwardVector.y;
				//temp =temp / dx2;
				flanker1.offsetX += temp * forwardVector.x;
				flanker1.offsetY += temp * forwardVector.y;
				
				
				dx = movableA.x - flanker2.x - flanker2.offsetX;
				dy = movableA.y - flanker2.y - flanker2.offsetY;
				temp = dx * forwardVector.x + dy * forwardVector.y;
				temp *= 2;
				
				flanker2.offsetX += temp * forwardVector.x;
				flanker2.offsetY += temp * forwardVector.y;
				
				rearGuard.offsetX = 0;
				rearGuard.offsetY = 0;
				
			}
			

				
		}
		
		private var forwardVector:Vector3D = new Vector3D();
		
		private var testLeader:MovableCircle = new MovableCircle(1, 1, 1);
		
		private function getClosestIntersectionEnv(testCirc:MovableCircle):DynamicIntersection {
			var closestIntersect:DynamicIntersection = null;
			for each(var obstacle:IDynamicIntersectionTestAble in simulation.immovables) {
				var intersect:DynamicIntersection = obstacle.dIntersectMovableCircle(testCircle, 1);
				
				if (intersect != null) {
					if (closestIntersect == null || closestIntersect.dt > intersect.dt) {
						closestIntersect = intersect;
					}
				}
			}
			
			return closestIntersect;
		}
		
		private function checkLinkToLeaderBlocked(movable:MovableCircle, person:Person, radius:Number, customLeader:MovableCircle=null):Boolean 
		{
			
			//radius -= 2;
			
			if (!customLeader) customLeader = movableA;
		
			for each(var obstacle:IDynamicIntersectionTestAble in simulation.immovables) {
				
				//if (!(obstacle is ImmovableCircleOuter) ) return false
				testCircle.x = movable.x;
				testCircle.y = movable.y;
				testCircle.r = radius;
				testCircle.velocity.x = customLeader.x - movable.x;
				testCircle.velocity.y = customLeader.y - movable.y;
				var dist:Number = testCircle.velocity.length();
				
				testCircle.velocity.scale( (dist - testCircle.r - (obstacle is ImmovableCircleOuter ?  (obstacle as ImmovableCircleOuter).r : 0 )  ) / dist );
				
				var intersect:DynamicIntersection = obstacle.dIntersectMovableCircle(testCircle, 1);
				//if (intersect) throw new Error(intersect.dt + ", "+person.name);
				if ( intersect != null) return true;
				
			}
			return false;
		}
		
		
		
		
		
		private var springs:Array = [];
		private var footStepThreshold:Number = 16 * 16;
		private var _formationState:int;
		private var spreadMode:int = 0;
		public function setSpreadMode(val:int):void {
			if (val ==0) {
				spreadMode = val;
				targetSpringRest = LARGE_RADIUS * 1 + 1;
				
			}
			else if (val == 1) {
				spreadMode = val;
				targetSpringRest =  LARGE_RADIUS * 1 + 1;
				
			}
			else  {
				spreadMode = 2;
				targetSpringRest =  LARGE_RADIUS * 2 + 1;
			}
			
		}
		
		public var lastRearGuardSlot:int=2;
		
		public function setFootstepThreshold(val:Number):void {
			footStepThreshold = val * val;
		}
		public var targetSpringRest:Number;
		public var enableFootsteps:Boolean = true;
		
		public function transitSpringLength(spring:*, targetSpringRest:Number):void {
			if (spring.targetLength >= 0) {
				targetSpringRest = spring.targetLength;
			}
			const springSpeed:Number = SPRING_SPEED;
			var decresing:Boolean = targetSpringRest <= spring.restLength;
			var diff:Number = decresing ? spring.restLength - targetSpringRest : targetSpringRest - spring.restLength;
			spring.restLength += (decresing  ? -springSpeed : springSpeed);
			if (diff < springSpeed) spring.restLength = targetSpringRest;
			
			
		}
		
		public static var LARGE_RADIUS:Number = 16;
		public static var SMALL_RADIUS:Number = LARGE_RADIUS * .45;

		static public const NULL_SPRING:Spring = new Spring( new MovableCircle(0,0,2), new MovableCircle(1,1,2) );

		public static var SPRING_SPEED:Number = 1;
		public var footStepCallback:Function;
		public var rearGuard:MovableChar;
		
		public function createScene(): void
		{
			
			
			var movableCircle: ImmovableCircleOuter;
			movableCircle = new ImmovableCircleOuter( 128, 196, 8 );
			simulation.addImmovable( movableCircle );
			movableCircle = new ImmovableCircleOuter( 64, 196, 16 );
			simulation.addImmovable( movableCircle );
			movableCircle = new ImmovableCircleOuter( 160, 196, 8 );
			simulation.addImmovable( movableCircle );
			movableCircle = new ImmovableCircleOuter( 196+16, 196, 16 );
			simulation.addImmovable( movableCircle );
			var i:int = 44;
			while (--i > -1) {
				movableCircle = new ImmovableCircleOuter( Math.random()*400, 220+Math.random()*200, 16 );
			simulation.addImmovable( movableCircle );
			}
			

			
			var immovable: Immovable;
			
			//-- just some immovables
			immovable = new ImmovableCircleInnerSegment( 128, HEIGHT - 128, 128, Math.PI/2, Math.PI );
			simulation.addImmovable( immovable );
			immovable = new ImmovableCircleInnerSegment( 128, 128, 128, Math.PI, -Math.PI/2 );
			simulation.addImmovable( immovable );
			immovable = new ImmovableCircleOuterSegment( WIDTH - 64, HEIGHT/2, 64, Math.PI, -Math.PI/2 );
			simulation.addImmovable( immovable );
			immovable = new ImmovableGate( WIDTH - 64, HEIGHT/2 - 64, WIDTH, HEIGHT/2 - 64 );
			simulation.addImmovable( immovable );
			immovable = new ImmovablePoint( WIDTH - 128, HEIGHT/2 );
			simulation.addImmovable( immovable );
			immovable = new ImmovableGate( WIDTH, HEIGHT/2, WIDTH - 128, HEIGHT/2 );
			simulation.addImmovable( immovable );
			immovable = new ImmovableBezierQuadric( WIDTH/2, HEIGHT, WIDTH-192, HEIGHT/2, WIDTH, HEIGHT, false );
			simulation.addImmovable( immovable );
		}
		
		public function redrawImmovables():void 
		{
			iShape.graphics.clear();
			drawImmovables();
		}
		
		public function displaceMovables(x:Number, y:Number):void 
		{
			
			
			
			movableA.x += x;
			movableB.x += x;
			movableC.x += x;
			movableD.x += x;
			
			movableA.y += y;
			movableB.y += y;
			movableC.y += y;
			movableD.y += y;
			
				if( mouseSpring )
			{
				simulation.removeForce( mouseSpring );
			
				mouseSpring = null;
			}
			
			
		// todo: shorten footstep length only, but this can be done preioduically...//ny existing footstep springs...
		//footsteps.length = 0;
		//footsteps[0] = movableA.x;
		//footsteps[1] = movableA.y;
		//snakeFootsteps[0] = movableA.x;
		//snakeFootsteps[1] = movableA.y;
		
		// or update all footsteps
		
		///*
		i = footsteps.length  - 1;
		while ( i > 0) {
			footsteps[i] += y;
			footsteps[i - 1] += x;

			i -= 2;
		}
	//	*/
			
			
			
			//if (movableA.x != 0 || movableA.y!=0) throw new Error("SHOULD NOT BE!:"+movableA.x + ", "+movableA.y);
		var i:int = fixedSprings.length;
				while (--i > -1) {
					
						
						fixedSprings[i].x = movableA.x;
						fixedSprings[i].y = movableA.y;
					
					
				}
			
				//
			personA.x = movableA.x; personA.y = movableA.y;
			///*	
			personB.x = movableB.x; personB.y = movableB.y;
			
			personC.x = movableA.x; personC.y = movableC.y;
			
			personD.x = movableD.x; personD.y = movableD.y;
			//*/
			
		}
	
		
		public function get formationState():int 
		{
			return _formationState;
		}
	}
}
import flash.display.Sprite;
import flash.geom.Vector3D;

class Person extends Sprite {
	
	private var forwardVec:Vector3D = new Vector3D();
	public var speed:Number;
	public var speedCap:Number;
	

	
	public function Person(color:uint, name:String, radius:Number, speed:Number=222) {
		this.speed = speed;
		graphics.beginFill(color, 1);
		graphics.drawCircle(0, 0, radius  );
		this.name = name;
		
		alpha = name != "leader" ? 0: .2 ;
	//	visible = name === "leader";
	
	visible = false;
	}
	
	public function moveToTargetLocation(targetX:Number, targetY:Number):void {
		forwardVec.x = (targetX - x)
		forwardVec.y = (targetY - y);
		if (forwardVec.lengthSquared > speed*speed) {
			forwardVec.normalize();
			forwardVec.x *= speed;
			forwardVec.y *= speed;
			x += forwardVec.x;
			y += forwardVec.y;
		}
		else {
			x = targetX;
			y = targetY;
		}
		
		
		 
	}
	
}

