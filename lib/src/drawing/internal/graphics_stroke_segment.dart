part of stagexl.drawing.internal;

class GraphicsStrokeSegment extends GraphicsMesh {

  final GraphicsStroke stroke;
  final GraphicsPathSegment pathSegment;

  GraphicsStrokeSegment(GraphicsStroke stroke, GraphicsPathSegment pathSegment)
      : this.stroke = stroke,
        this.pathSegment = pathSegment,
        super(pathSegment.vertexCount * 2, pathSegment.vertexCount * 6) {

    if (pathSegment.vertexCount >= 2) {
      _calculateStroke();
    }
  }

  //---------------------------------------------------------------------------

  bool hitTest(double px, double py) {

    for (int i = 0; i < _indexCount - 2; i += 3) {

      var o1 = _indexBuffer[i + 0] * 2;
      var o2 = _indexBuffer[i + 1] * 2;
      var o3 = _indexBuffer[i + 2] * 2;

      var x1 = _vertexBuffer[o1 + 0] - px;
      var x2 = _vertexBuffer[o2 + 0] - px;
      var x3 = _vertexBuffer[o3 + 0] - px;
      if (x1 > 0 && x2 > 0 && x3 > 0) continue;
      if (x1 < 0 && x2 < 0 && x3 < 0) continue;

      var y1 = _vertexBuffer[o1 + 1] - py;
      var y2 = _vertexBuffer[o2 + 1] - py;
      var y3 = _vertexBuffer[o3 + 1] - py;
      if (y1 > 0 && y2 > 0 && y3 > 0) continue;
      if (y1 < 0 && y2 < 0 && y3 < 0) continue;

      var ab = x1 * y2 - x2 * y1;
      var bc = x2 * y3 - x3 * y2;
      var ca = x3 * y1 - x1 * y3;
      if (ab >= 0 && bc >= 0 && ca >= 0) return true;
      if (ab <= 0 && bc <= 0 && ca <= 0) return true;
    }

    return false;
  }

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------

  void _calculateStroke() {

    var length = pathSegment.vertexCount;
    var closed = pathSegment.closed;
    var vertices = pathSegment._vertexBuffer;

    var width = stroke.command.width;
    var jointStyle = stroke.command.jointStyle;
    var capsStyle = stroke.command.capsStyle;

    var v1x = 0.0, v1y = 0.0;
    var n1x = 0.0, n1y = 0.0;
    var v2x = 0.0, v2y = 0.0;
    var n2x = 0.0, n2y = 0.0;

    for (var i = -2; i <= length; i++) {

      // get next vertex
      var offset = ((i + 1) % length) * 2;
      v2x = vertices[offset + 0];
      v2y = vertices[offset + 1];

      // calculate next normal
      num vx = v2x - v1x;
      num vy = v1y - v2y;
      num vl = math.sqrt(vx * vx + vy * vy);
      n2x = 0.5 * width * vy / vl;
      n2y = 0.5 * width * vx / vl;

      // add indices
      if (i > 0 && (i < length || closed)) {
        var vertexCount = this.vertexCount;
        this.addIndices(vertexCount - 2, vertexCount - 1, vertexCount + 0);
        this.addIndices(vertexCount - 1, vertexCount + 0, vertexCount + 1);
      }

      // calculate vertices
      if (i == 0 && closed == false) {
        _addCapsStart(v1x, v1y, n2x, n2y, capsStyle);
      } else if (i == length - 1 && closed == false) {
        _addCapsEnd(v1x, v1y, n1x, n1y, capsStyle);
      } else if (i >= 0 && (i < length || closed)) {
        _addJoint(v1x, v1y, n1x, n1y, n2x, n2y, jointStyle);
      }

      // shift vertices and normals
      v1x = v2x; v1y = v2y;
      n1x = n2x; n1y = n2y;
    }
  }

  //---------------------------------------------------------------------------

  void _addCapsStart(num vx, num vy, num nx, num ny, CapsStyle capsStyle) {
    if (capsStyle == CapsStyle.SQUARE) {
      this.addVertex(vx + nx - ny, vy + ny + nx);
      this.addVertex(vx - nx - ny, vy - ny + nx);
    } else if (capsStyle == CapsStyle.ROUND) {
      _addArc(vx, vy, nx, ny, 0.0 - math.PI);
      this.addVertex(vx + nx, vy + ny);
      this.addVertex(vx - nx, vy - ny);
    } else {
      this.addVertex(vx + nx, vy + ny);
      this.addVertex(vx - nx, vy - ny);
    }
  }

  //---------------------------------------------------------------------------

  void _addCapsEnd(num vx, num vy, num nx, num ny, CapsStyle capsStyle) {
    if (capsStyle == CapsStyle.SQUARE) {
      this.addVertex(vx + nx + ny, vy + ny - nx);
      this.addVertex(vx - nx + ny, vy - ny - nx);
    } else if (capsStyle == CapsStyle.ROUND) {
      _addArc(vx, vy, nx, ny, math.PI);
      this.addVertex(vx + nx, vy + ny);
      this.addVertex(vx - nx, vy - ny);
    } else {
      this.addVertex(vx + nx, vy + ny);
      this.addVertex(vx - nx, vy - ny);
    }
  }

  //---------------------------------------------------------------------------

  void _addJoint(num vx, num vy, num n1x, num n1y, num n2x, num n2y, JointStyle jointStyle) {

    // TODO: add support for JointStyle.ROUND
    // TODO: add support for JointStyle.BEVEL
    // TODO: calculate correct miter limit

    num id = (n2x * n1y - n2y * n1x);
    num it = (n2x * (n1x - n2x) + n2y * (n1y - n2y)) / id;
    num ix = n1x - it * n1y;
    num iy = n1y + it * n1x;
    this.addVertex(vx + ix, vy + iy);
    this.addVertex(vx - ix, vy - iy);
  }

  //---------------------------------------------------------------------------

  void _addArc(num vx, num vy, num nx, num ny, num angle) {

    // TODO: adjust steps

    int steps = (10 * angle / math.PI).abs().ceil();
    int count = this.vertexCount;

    num cosR = math.cos(angle / steps);
    num sinR = math.sin(angle / steps);
    num tx = vx - vx * cosR + vy * sinR;
    num ty = vy - vx * sinR - vy * cosR;
    num ax = vx - nx;
    num ay = vy - ny;

    this.addVertex(vx + nx, vy + ny);
    this.addVertex(vx - nx, vy - ny);

    for (int s = 0; s < steps - 1; s++) {
      var bx = ax * cosR - ay * sinR + tx;
      var by = ax * sinR + ay * cosR + ty;
      this.addVertex(ax = bx, ay = by);
      this.addIndices(count + s + 1, count + s + 2, count);
    }
  }

}
