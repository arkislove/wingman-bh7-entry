/// ------------------------------
/// Shapes2D
/// ------------------------------
@block shape
#define Circle          0
#define CircleTextured  1

#define Rect            2
#define RectTextured    3
@end

@vs vs_shape
@include_block shape

/// Quad positions.
const vec2 positions[] = {
  {-1, -1}, {-1, 1}, { 1, 1},   // bottom-left, top-left, top-right
  { 1, 1}, { 1, -1}, { -1, -1}, // top right - bottom-right, bottom-left
};

/// Quad uvs.
const vec2 uvs[] = {
  {0, 0}, {0, 1}, { 1, 1},   // bottom-left, top-left, top-right
  {1, 1}, {1, 0}, {0, 0},    // top right - bottom-right, bottom-left
};

/// units are in pixels
in ivec2 pos;
/// z -> tint : i32 (rgba8)
in uint rgba;
/// w -> geometry: union (radius: u32 , {w, h}))
in uint geometry;

layout(binding=0) uniform canvas {
  int canvas_width;
  int canvas_height;
};

layout(binding=1) uniform context {
  int type; // Circle, CircleTextured, Rect, etc..
};

out vec2 local_pos;
out vec2 uv;
out vec4 tint;
out flat uint shape_type;

/// Takes in a int and transforms it to an rgba8 f32.
vec4 unpack_rgba8(uint u) {
    vec4 color;
    color.r = float((u >> 24U) & 0xFFU) / 255.0;
    color.g = float((u >> 16U) & 0xFFU) / 255.0;
    color.b = float((u >> 8U)  & 0xFFU) / 255.0;
    color.a = float((u >> 0U)  & 0xFFU) / 255.0;
    return color;
}

void main() {
  // vertex index in the quad
  uint vidx = gl_VertexIndex % 6;

  // positions and uv as quad
  uv = uvs[vidx];
  local_pos = positions[vidx];

  // extract shape type, tint and geometry
  shape_type = type;
  tint = unpack_rgba8(rgba);
  uint g = geometry;

  // global position
  vec2 point = pos.xy;

  if(shape_type == Rect || shape_type == RectTextured) {
    uint w = g & 0xFFFFu;
    uint h = g >> 16 & 0xFFFFu;

    point.x += positions[vidx].x * w;
    point.y += positions[vidx].y * h;
  } else if(shape_type == Circle || shape_type == CircleTextured) {
    // g is interpreted as radius
    uint radius = g;
    point += positions[vidx] * radius;
  }

  // convert point to pixel coords
  vec2 screen_size = vec2(canvas_width, canvas_height);
  point.x = (point.x / screen_size.x) * 2.0 - 1.0;
  point.y = 1 - (point.y / screen_size.y) * 2.0; // flip why to support top left origin

  gl_Position = vec4(point, 1.0f, 1.0);
}

@end

@fs fs_shape
@include_block shape

in vec2 local_pos;
in vec2 uv;
in vec4 tint;
in flat uint shape_type;

out vec4 frag_color;

float sd_circle(vec2 p, float r) {
  return length(p) - r;
}

float sd_rect(vec2 p, vec2 b) {
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

void main() {
  float s = 0.0;

  if(shape_type == Rect || shape_type == RectTextured) {
    s += sd_rect(local_pos, vec2(1.0, 1.0));
  } else if(shape_type == Circle || shape_type == CircleTextured) {
    s += sd_circle(local_pos, 1);
  }

  float alpha = clamp(-s / fwidth(s), 0.0, 1.0);

  const float t = 0.05;
  float is_outline = step(abs(s), t) * alpha;

  frag_color = vec4(alpha) * tint;
}

@end

@fs fs_textured_shape
@include_block shape

in vec2 local_pos;
in vec2 uv;
in vec4 tint;
in flat uint shape_type;

out vec4 frag_color;

layout(binding=3) uniform texture2D tex;
layout(binding=3) uniform sampler smp;

float sd_circle(vec2 p, float r) {
  return length(p) - r;
}

float sd_rect(vec2 p, vec2 b) {
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

void main() {
  float s = 0.0;

  if(shape_type == Rect || shape_type == RectTextured) {
    s += sd_rect(local_pos, vec2(1.0, 1.0));
  } else if(shape_type == Circle || shape_type == CircleTextured) {
    s += sd_circle(local_pos, 1);
  }

  float alpha = clamp(-s / fwidth(s), 0.0, 1.0);

  const float t = 0.05;
  float is_outline = step(abs(s), t) * alpha;

  vec4 color = texture(sampler2D(tex, smp), uv) * (1.0 - is_outline);
  color += vec4(0.0, 0.0, 0.0, 1.0) * is_outline;

  frag_color = vec4(alpha) * color;
}

@end

@program shape vs_shape fs_shape
@program shape_textured vs_shape fs_textured_shape
