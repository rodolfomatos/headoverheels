// 2D Grid Physics for 2:1 Dimetric Isometric Games
// Fixed-timestep, deterministic, AABB collision

import 'package:vector_math/vector_math.dart';

/// Physics configuration constants
const int kPhysicsHz = 60;
const double kFixedDt = 1.0 / kPhysicsHz;
const int kMaxSubSteps = 4;

/// Physics body types
enum BodyType { dynamic, kinematic, static }

/// Collision categories for filtering
class CollisionCategory {
  static const int none = 0;
  static const int character = 1 << 0;
  static const int tile = 1 << 1;
  static const int entity = 1 << 2;
  static const int trigger = 1 << 3;
  static const int projectile = 1 << 4;
  static const int all = ~0;
}

/// Axis-Aligned Bounding Box in grid space
class AABB {
  final double minX, minY, maxX, maxY;

  const AABB({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  AABB.fromPositionSize(
    Vector3 pos,
    double width,
    double height, {
    double z = 0,
  }) : minX = pos.x - width / 2,
       minY = pos.y - height / 2,
       maxX = pos.x + width / 2,
       maxY = pos.y + height / 2;

  double get width => maxX - minX;
  double get height => maxY - minY;
  Vector2 get center => Vector2((minX + maxX) / 2, (minY + maxY) / 2);
  Vector3 get center3 => Vector3(center.x, center.y, 0);

  bool overlaps(AABB other) {
    return minX < other.maxX &&
        maxX > other.minX &&
        minY < other.maxY &&
        maxY > other.minY;
  }

  bool contains(Vector2 point) {
    return point.x >= minX &&
        point.x <= maxX &&
        point.y >= minY &&
        point.y <= maxY;
  }

  AABB expandedBy(double margin) {
    return AABB(
      minX: minX - margin,
      minY: minY - margin,
      maxX: maxX + margin,
      maxY: maxY + margin,
    );
  }

  AABB movedBy(Vector2 delta) {
    return AABB(
      minX: minX + delta.x,
      minY: minY + delta.y,
      maxX: maxX + delta.x,
      maxY: maxY + delta.y,
    );
  }

  /// Minkowski sum for swept collision
  AABB minkowskiSum(AABB other) {
    return AABB(
      minX: minX - other.maxX,
      minY: minY - other.maxY,
      maxX: maxX - other.minX,
      maxY: maxY - other.minY,
    );
  }

  @override
  String toString() => 'AABB(min: ($minX, $minY), max: ($maxX, $maxY))';
}

/// Collision result
class CollisionResult {
  final bool collided;
  final Vector2 normal;
  final double penetration;
  final Vector2 contactPoint;

  const CollisionResult({
    required this.collided,
    required this.normal,
    required this.penetration,
    required this.contactPoint,
  });

  static final none = CollisionResult(
    collided: false,
    normal: Vector2(0, 0),
    penetration: 0,
    contactPoint: Vector2(0, 0),
  );
}

/// Physics body component
class PhysicsBody {
  final BodyType type;
  final AABB bounds;
  final int collisionCategory;
  final int collisionMask;
  final double mass;
  final double friction;
  final double restitution;

  Vector2 velocity = Vector2.zero();
  Vector2 acceleration = Vector2.zero();
  Vector2 position = Vector2.zero();

  PhysicsBody({
    required this.type,
    required this.bounds,
    this.collisionCategory = CollisionCategory.all,
    this.collisionMask = CollisionCategory.all,
    this.mass = 1.0,
    this.friction = 0.0,
    this.restitution = 0.0,
  }) : position = bounds.center;

  bool get isStatic => type == BodyType.static;
  bool get isDynamic => type == BodyType.dynamic;

  AABB get currentBounds => bounds.movedBy(position - bounds.center);

  void applyForce(Vector2 force) {
    if (isDynamic) {
      acceleration += force / mass;
    }
  }

  void applyImpulse(Vector2 impulse) {
    if (isDynamic) {
      velocity += impulse / mass;
    }
  }

  void step(double dt) {
    if (!isDynamic) return;

    // Semi-implicit Euler
    velocity += acceleration * dt;
    velocity *= (1.0 - friction).clamp(0.0, 1.0);
    position += velocity * dt;
    acceleration = Vector2.zero();
  }
}

/// Fixed-timestep physics world
class PhysicsWorld {
  final List<PhysicsBody> bodies = [];
  double _accumulator = 0.0;

  void addBody(PhysicsBody body) {
    bodies.add(body);
  }

  void removeBody(PhysicsBody body) {
    bodies.remove(body);
  }

  void step(double dt) {
    _accumulator += dt;
    int steps = 0;

    while (_accumulator >= kFixedDt && steps < kMaxSubSteps) {
      _stepFixed(kFixedDt);
      _accumulator -= kFixedDt;
      steps++;
    }
  }

  void _stepFixed(double dt) {
    // 1. Apply gravity and forces
    for (final body in bodies) {
      if (body.isDynamic) {
        // Gravity handled by game logic
      }
    }

    // 2. Integrate positions
    for (final body in bodies) {
      body.step(dt);
    }

    // 3. Collision detection & resolution
    _resolveCollisions();
  }

  void _resolveCollisions() {
    for (int i = 0; i < bodies.length; i++) {
      final a = bodies[i];
      if (a.isStatic) continue;

      for (int j = i + 1; j < bodies.length; j++) {
        final b = bodies[j];

        if ((a.collisionCategory & b.collisionMask) == 0 ||
            (b.collisionCategory & a.collisionMask) == 0) {
          continue;
        }

        final result = _testCollision(a, b);
        if (result.collided) {
          _resolveCollision(a, b, result);
        }
      }
    }
  }

  CollisionResult _testCollision(PhysicsBody a, PhysicsBody b) {
    final boundsA = a.currentBounds;
    final boundsB = b.currentBounds;

    if (!boundsA.overlaps(boundsB)) {
      return CollisionResult.none;
    }

    // AABB vs AABB - find minimum translation vector
    final dx = boundsB.center.x - boundsA.center.x;
    final dy = boundsB.center.y - boundsA.center.y;
    final hw = (boundsA.width + boundsB.width) / 2;
    final hh = (boundsA.height + boundsB.height) / 2;

    double overlapX = hw - dx.abs();
    double overlapY = hh - dy.abs();

    if (overlapX < overlapY) {
      // Separate on X axis
      final normal = Vector2(dx > 0 ? -1 : 1, 0);
      return CollisionResult(
        collided: true,
        normal: normal,
        penetration: overlapX,
        contactPoint: boundsA.center + normal * (overlapX / 2),
      );
    } else {
      // Separate on Y axis
      final normal = Vector2(0, dy > 0 ? -1 : 1);
      return CollisionResult(
        collided: true,
        normal: normal,
        penetration: overlapY,
        contactPoint: boundsA.center + normal * (overlapY / 2),
      );
    }
  }

  void _resolveCollision(PhysicsBody a, PhysicsBody b, CollisionResult result) {
    final separation = result.normal * result.penetration;

    if (a.isDynamic && b.isDynamic) {
      a.position -= separation / 2;
      b.position += separation / 2;

      // Elastic collision response
      final relVel = a.velocity - b.velocity;
      final velAlongNormal = relVel.dot(result.normal);
      if (velAlongNormal > 0) return;

      final restitution = (a.restitution + b.restitution) / 2;
      final impulseMag =
          -(1 + restitution) * velAlongNormal / (1 / a.mass + 1 / b.mass);
      final impulse = result.normal * impulseMag;

      a.applyImpulse(-impulse);
      b.applyImpulse(impulse);
    } else if (a.isDynamic) {
      a.position -= separation;
      // Reflect velocity
      final velAlongNormal = a.velocity.dot(result.normal);
      if (velAlongNormal < 0) {
        a.velocity -= result.normal * velAlongNormal * (1 + a.restitution);
      }
    } else if (b.isDynamic) {
      b.position += separation;
      final velAlongNormal = b.velocity.dot(result.normal);
      if (velAlongNormal < 0) {
        b.velocity -= result.normal * velAlongNormal * (1 + b.restitution);
      }
    }
  }

  /// Raycast against all static bodies
  List<CollisionResult> raycast(
    Vector2 origin,
    Vector2 direction,
    double maxDistance,
  ) {
    final results = <CollisionResult>[];
    for (final body in bodies) {
      if (!body.isStatic) continue;
      // Simple AABB raycast
      // TODO: implement proper raycast
    }
    return results;
  }
}

/// Character controller with grid-based movement
class CharacterController {
  final PhysicsBody body;
  final double walkSpeed;
  final double runSpeed;
  final double jumpHeight;
  final double gravity;
  final double airControl;

  Vector2 _moveInput = Vector2.zero();
  bool _isGrounded = false;
  int _jumpFrames = 0;
  int _coyoteFrames = 0;

  CharacterController({
    required this.body,
    this.walkSpeed = 2.0,
    this.runSpeed = 4.0,
    this.jumpHeight = 2.0,
    this.gravity = 20.0,
    this.airControl = 0.5,
  });

  void setMoveInput(Vector2 input) {
    _moveInput = Vector2(input.x.clamp(-1.0, 1.0), input.y.clamp(-1.0, 1.0));
  }

  void setGrounded(bool value) {
    _isGrounded = value;
  }

  bool get isGrounded => _isGrounded;

  void jump() {
    if (_canJump()) {
      body.velocity = Vector2(body.velocity.x, -jumpHeight * gravity * 0.5);
      _jumpFrames = 10;
      _coyoteFrames = 0;
    }
  }

  bool _canJump() => _isGrounded || _coyoteFrames > 0;

  void update(double dt) {
    // Horizontal movement
    final targetSpeed = _moveInput.length2 > 0.25 ? runSpeed : walkSpeed;
    final moveDir = _moveInput.normalized();

    if (_isGrounded) {
      body.velocity = Vector2(moveDir.x * targetSpeed, body.velocity.y);
    } else {
      // Air control
      body.velocity.x = _lerpDouble(
        body.velocity.x,
        moveDir.x * targetSpeed * airControl,
        airControl * dt * 10,
      );
    }

    // Gravity
    body.velocity.y += gravity * dt;

    // Coyote time
    if (!_isGrounded) {
      _coyoteFrames = (_coyoteFrames > 0 ? _coyoteFrames - 1 : 0);
    }

    // Jump frames
    if (_jumpFrames > 0) _jumpFrames--;

    // Update grounded state (will be set by collision resolution)
    // _isGrounded = ...
  }

  double _lerpDouble(double a, double b, double t) =>
      a + (b - a) * t.clamp(0.0, 1.0);
}
