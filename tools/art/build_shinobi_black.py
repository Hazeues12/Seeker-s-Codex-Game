"""Rebuild the skinned Shinobi Black costume from its front/back design sheet.

From the project root:
    blender -b --factory-startup --python tools/art/build_shinobi_black.py
Add -- --preview /tmp/shinobi-preview to render the three modeling views.
"""

import argparse
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Vector

TAU = math.tau
FRONT = Vector((0.0, 1.0, 0.0))
UP = Vector((0.0, 0.0, 1.0))
ROOT = Path(__file__).resolve().parents[2]

CLOTH = "#2B2A30"
PANTS = "#28272D"
WRAP = "#24232A"
EDGE = "#42404A"
INK = "#18171D"
HAIR = "#232229"
HAIR_GLINT = "#3B3842"
SKIN = "#D6A58C"
LEATHER = "#222129"
METAL = "#5F5752"


def linear_channel(value):
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def paint(color, shade=1.0):
    return tuple(linear_channel(min(1.0, int(color[i:i + 2], 16) / 255 * shade))
                 for i in (1, 3, 5)) + (1.0,)


def smooth(value):
    value = min(1.0, max(0.0, value))
    return value * value * (3.0 - 2.0 * value)


def blend(first, second, weight):
    if weight <= 0.001:
        return {first: 1.0}
    if weight >= 0.999:
        return {second: 1.0}
    return {first: 1.0 - weight, second: weight}


def sample(rows, value):
    """Interpolate the sculpt profile at a height or a sweep parameter."""
    for low, high in zip(rows, rows[1:]):
        if value <= high[0]:
            t = min(1.0, max(0.0, (value - low[0]) / (high[0] - low[0])))
            return [a + (b - a) * t for a, b in zip(low[1:], high[1:])]
    return rows[-1][1:]


class PaintedMesh:
    """A mesh layer with per-vertex paint and skin weights."""

    def __init__(self, name):
        self.name = name
        self.points = []
        self.faces = []
        self.colors = []
        self.weights = []

    def vertex(self, point, color, weights, shade=1.0):
        index = len(self.points)
        self.points.append(point)
        self.colors.append(paint(color, shade))
        self.weights.append(weights if isinstance(weights, dict) else {weights: 1.0})
        return index

    def join(self, low, high, closed=True, skip=()):
        for j in range(len(low) if closed else len(low) - 1):
            if j not in skip:
                k = (j + 1) % len(low)
                self.faces.append((low[j], low[k], high[k], high[j]))

    def tube(self, path, color, weights, count=12, grain=0.0, flatten=False):
        """Sweep a closed elliptical section along fitted control rings.

        Each control ring is (x, y, z, width, thickness), using the front
        direction as the section's thickness axis where possible.
        """
        loops = []
        for i, (x, y, z, width, depth) in enumerate(path):
            center = Vector((x, y, z))
            axis = (Vector(path[min(i + 1, len(path) - 1)][:3])
                    - Vector(path[max(i - 1, 0)][:3])).normalized()
            hint = FRONT if abs(axis.dot(FRONT)) < 0.94 else UP
            thickness_axis = (hint - axis * axis.dot(hint)).normalized()
            width_axis = thickness_axis.cross(axis)
            ring = []
            for j in range(count):
                angle = TAU * j / count
                c, s = math.cos(angle), math.sin(angle)
                if flatten:
                    c = math.copysign(abs(c) ** 0.50, c)
                    s = math.copysign(abs(s) ** 0.50, s)
                point = center + width_axis * (width * c) + thickness_axis * (depth * s)
                shade = 1.0 + grain * (0.64 * math.sin(angle * 3.0 + i * 1.13)
                                       + 0.36 * math.cos(angle * 7.0 - i * 0.51))
                weight = weights(point) if callable(weights) else weights
                ring.append(self.vertex(point, color, weight, shade))
            if loops:
                self.join(loops[-1], ring)
            loops.append(ring)
        self.faces += [tuple(reversed(loops[0])), tuple(loops[-1])]
        return loops

    def strip(self, points, widths, color, weights, relief=0.0, sections=4, front=FRONT):
        """A fitted, gently creased fabric or ink ribbon along a 3D path."""
        previous = None
        for i, (center, width) in enumerate(zip(points, widths)):
            center = Vector(center)
            tangent = Vector(points[min(i + 1, len(points) - 1)]) - Vector(points[max(i - 1, 0)])
            across = tangent.cross(front).normalized()
            row = []
            for j in range(sections + 1):
                u = j / sections * 2.0 - 1.0
                point = center + across * (width * u) + front * (relief * (1.0 - abs(u)))
                shade = 0.74 + 0.29 * (1.0 - abs(u)) + 0.11 * u
                weight = weights(point) if callable(weights) else weights
                row.append(self.vertex(point, color, weight, shade))
            if previous:
                self.join(previous, row, False)
            previous = row

    def fitted_strip(self, points, widths, surface, color, weights, relief):
        """Fit each edge of a panel independently to the sculpt underneath."""
        prev = None
        for i, ((x, z, lift), width) in enumerate(zip(points, widths)):
            before, after = points[max(0, i - 1)], points[min(i + 1, len(points) - 1)]
            across = Vector((after[1] - before[1], before[0] - after[0])).normalized()
            row = []
            for j in range(7):
                u = (j - 3) / 3
                xx, zz = x + across.x * width * u, z + across.y * width * u
                depth = surface(xx, zz) + lift + relief * (1 - abs(u))
                point = (xx, depth, zz)
                shade = .80 + .22 * (1 - abs(u)) + .08 * u
                row.append(self.vertex(point, color, weights(point), shade))
            if prev:
                self.join(prev, row, False)
            prev = row

    def create(self, rig):
        mesh = bpy.data.meshes.new(self.name)
        mesh.from_pydata(self.points, [], self.faces)
        mesh.update()
        color_layer = mesh.color_attributes.new(name="Palette", type="FLOAT_COLOR", domain="POINT")
        color_layer.data.foreach_set("color", [channel for color in self.colors for channel in color])
        mesh.color_attributes.active_color = color_layer
        for poly in mesh.polygons:
            poly.use_smooth = True
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.collection.objects.link(obj)
        obj.parent = rig
        skin = obj.modifiers.new("Seeker skin", "ARMATURE")
        skin.object = rig
        groups = {}
        for index, weights in enumerate(self.weights):
            for name, amount in weights.items():
                if name not in groups:
                    groups[name] = obj.vertex_groups.new(name=name)
                groups[name].add([index], amount, "REPLACE")
        material = bpy.data.materials.new(self.name)
        material.use_nodes = True
        material.use_backface_culling = self.name != "Details"
        nodes = material.node_tree.nodes
        palette = nodes.new("ShaderNodeVertexColor")
        palette.layer_name = "Palette"
        material.node_tree.links.new(palette.outputs["Color"], nodes.get("Principled BSDF").inputs["Base Color"])
        nodes.get("Principled BSDF").inputs["Roughness"].default_value = 1.0
        mesh.materials.append(material)
        return obj


# Character coordinates are X across, +Y forward, Z up in Blender. Export
# converts +Y to Godot's -Z forward. The feet stay at the existing actor origin.
BODY = [
    (1.18, .238, .127, -.004), (1.24, .237, .131, -.009),
    (1.30, .224, .131, -.008), (1.36, .209, .123, -.006),
    (1.43, .208, .119, -.007), (1.50, .217, .128, -.004),
    (1.57, .236, .144, -.002), (1.64, .256, .153, .004),
    (1.70, .274, .155, .010), (1.76, .282, .149, .008),
    (1.82, .278, .133, .001), (1.87, .253, .114, -.002),
    (1.91, .205, .091, -.009), (1.95, .118, .080, -.010),
    (1.98, .092, .074, -.009),
]

HEAD = [
    (1.975, .055, .057, .008), (2.008, .075, .080, .008),
    (2.041, .100, .105, .006), (2.080, .120, .112, .003),
    (2.122, .135, .125, .002), (2.159, .140, .126, .004),
    (2.194, .142, .122, .005), (2.222, .142, .121, .006),
    (2.252, .143, .121, .005), (2.284, .140, .124, .001),
    (2.320, .130, .119, -.006), (2.354, .108, .101, -.009),
    (2.381, .079, .077, -.012), (2.403, .046, .047, -.014),
    (2.415, .010, .011, -.015),
]


def spine_weight(point):
    return blend("Pelvis", "Chest", smooth((point[2] - 1.32) / .28))


def face_depth(x, z):
    width, depth, offset = sample(HEAD, z)
    curve = max(0.0, 1.0 - (x / width) ** 2) ** .34
    nose = .022 * math.exp(-(x / .034) ** 2 - ((z - 2.155) / .024) ** 2)
    cheek = .003 * math.exp(-((abs(x) - .079) / .031) ** 2 - ((z - 2.159) / .040) ** 2)
    return offset + depth * curve + nose + cheek


def coat_depth(x, z):
    width, depth, offset = sample(BODY, z)
    return offset + depth * math.sqrt(max(.025, 1.0 - (x / width) ** 2))


def build_jacket(shell, skin, details):
    count = 32
    cut_low, cut_high, cut_half_width = 7, 11, 3
    loops = []
    for i, (z, width, depth, offset) in enumerate(BODY):
        ring = []
        for j in range(count):
            angle = j * TAU / count
            # The broad folds turn into diagonals across the torso.
            crease = math.sin(3.0 * angle + z * 18) * .005 + math.sin(7.0 * angle - z * 19) * .003
            point = ((width + crease) * math.cos(angle),
                     offset + (depth + crease) * math.sin(angle), z)
            weight = spine_weight(point)
            ring.append(shell.vertex(point, CLOTH, weight, 1.0 + crease * 15))
        if loops:
            skip = ()
            if cut_low < i <= cut_high:
                skip = {(side + j) % count for side in (0, count // 2)
                        for j in range(-cut_half_width, cut_half_width)}
            shell.join(loops[-1], ring, skip=skip)
        loops.append(ring)
    shell.faces += [tuple(reversed(loops[0])), tuple(loops[-1])]

    # Stitch the sleeve loops into shoulder openings in the jacket mesh.
    for side in (-1, 1):
        suffix = "L" if side < 0 else "R"
        middle = 0 if side > 0 else count // 2
        left, right = middle - cut_half_width, middle + cut_half_width
        rim = [(cut_low, j) for j in range(left, right + 1)]
        rim += [(i, right) for i in range(cut_low + 1, cut_high + 1)]
        rim += [(cut_high, j) for j in range(right - 1, left - 1, -1)]
        rim += [(i, left) for i in range(cut_high - 1, cut_low, -1)]
        rim_indices = [loops[i][j % count] for i, j in rim]
        angles = [math.atan2((shell.points[v][2] - 1.755) / .115, shell.points[v][1] / .082)
                  for v in rim_indices]
        previous = rim_indices
        sleeve = [
            (.286, .001, 1.755, .105, .122), (.330, .003, 1.699, .112, .122),
            (.357, .003, 1.645, .114, .103), (.384, .011, 1.578, .092, .096),
            (.409, .018, 1.526, .095, .094), (.422, .028, 1.483, .082, .077),
            (.433, .032, 1.454, .089, .082), (.440, .043, 1.421, .072, .071),
            (.448, .045, 1.383, .066, .067), (.460, .050, 1.328, .058, .060),
            (.469, .059, 1.269, .052, .054), (.478, .066, 1.213, .045, .049),
        ]
        arm = f"UpperArm_{suffix}"
        forearm = f"Forearm_{suffix}"
        for row, (x, y, z, depth, radius) in enumerate(sleeve):
            ring = []
            for j, angle in enumerate(angles):
                crease = math.sin(angle * 3.0 + row * 1.2) * (.008 if row < 8 else .002)
                rise = (radius + crease) * math.sin(angle)
                point = (side * (x + rise * .68), y + (depth + crease) * math.cos(angle),
                         z + rise * .73)
                weight = blend(arm, forearm, smooth((1.54 - z) / .125))
                if row < 2:
                    weight = blend("Chest", arm, .65 if row == 0 else .92)
                ring.append(shell.vertex(point, CLOTH if row < 8 else WRAP, weight, 1.0 + 20 * crease))
            shell.join(previous, ring)
            previous = ring
        shell.faces.append(tuple(previous))
        arm_wraps(details, side, forearm)
        build_glove(shell, skin, side, f"Hand_{suffix}")

    # Cross-cut lapels sit on the cloth, turning into the waistband.
    for side in (-1, 1):
        points = [(side * x, z, .019 if side > 0 else .011) for x, z in
                  [(.168, 1.888), (.130, 1.821), (.081, 1.759), (.027, 1.702),
                   (-.024, 1.641), (-.078, 1.573), (-.121, 1.512), (-.163, 1.454)]]
        details.fitted_strip(points, [.029, .044, .048, .058, .065, .065, .060, .030],
                             coat_depth, "#3E3A43" if side > 0 else "#36333B", spine_weight, .013)
    for side in (-1, 1):
        for i, points in enumerate([
            [(.192, 1.636, .009), (.177, 1.586, .011), (.130, 1.540, .008)],
            [(.186, 1.579, .012), (.152, 1.537, .011), (.088, 1.508, .009)],
        ]):
            details.fitted_strip([(x * side, z, lift) for x, z, lift in points],
                                 [.001, .014 - .004 * i, .001], coat_depth,
                                 "#37343D", spine_weight, .004)


def spiral(layer, curve, height, turns, width, color, weight, phase=0.0):
    """Folded textile wraps sampled over an elliptical limb profile."""
    prev = None
    start, end = height
    for j in range(85):
        t = j / 84
        angle = phase + turns * TAU * t
        row = []
        for side in (0.0, .2, 1.0):
            z = start + (end - start) * t + width * (side - .5)
            x, y, rx, ry = curve(z)
            bulge = .006 + .003 * math.sin(math.pi * side)
            point = (x + (rx + bulge) * math.cos(angle), y + (ry + bulge) * math.sin(angle), z)
            row.append(layer.vertex(point, color, weight, .78 if side == 0.0 else 1.05))
        if prev:
            layer.join(prev, row, False)
        prev = row


def arm_wraps(details, side, forearm):
    profile = [(1.19, .482, .066, .049, .046), (1.26, .470, .057, .052, .053),
               (1.33, .458, .050, .056, .055), (1.39, .446, .046, .062, .065)]

    def contour(z):
        x, y, rx, ry = sample(profile, z)
        return side * x, y, rx, ry

    spiral(details, contour, (1.218, 1.382), 3.25, .048, "#35313A", forearm, side * .5)
    spiral(details, contour, (1.223, 1.381), -2.3, .009, "#25232B", forearm, side * .4)


def build_glove(shell, skin, side, bone):
    x = side * .480
    shell.tube([(x, .063, 1.228, .045, .047), (x + side * .010, .063, 1.183, .055, .041),
                (x + side * .015, .057, 1.132, .058, .033),
                (x + side * .016, .057, 1.106, .049, .024)], LEATHER, bone, 12, .10)
    for finger in range(4):
        xx = x + side * (.059 - .027 * finger)
        length = (.060, .072, .078, .066)[finger]
        shell.tube([(xx, .057, 1.136, .016, .019),
                    (xx + side * .004, .064, 1.089, .014, .014)], LEATHER, bone, 8)
        skin.tube([(xx + side * .004, .064, 1.095, .013, .014),
                    (xx + side * .001, .075, 1.119 - length, .012, .013),
                    (xx - side * .005, .085, 1.107 - length, .007, .010)],
                   SKIN, bone, 8)
    shell.tube([(x - side * .026, .081, 1.178, .018, .024),
                (x - side * .054, .106, 1.139, .016, .017)], LEATHER, bone, 9)
    skin.tube([(x - side * .055, .107, 1.141, .016, .017),
                (x - side * .065, .118, 1.108, .014, .014),
                (x - side * .062, .122, 1.096, .007, .009)], SKIN, bone, 9)


def build_legs(shell, details):
    for side in (-1, 1):
        suffix = "L" if side < 0 else "R"
        thigh, calf, foot = (f"{name}_{suffix}" for name in ("Thigh", "Calf", "Foot"))

        def trouser_weight(point):
            z = point[2]
            if z > 1.15:
                return blend(thigh, "Pelvis", smooth((z - 1.15) / .16))
            return blend(calf, thigh, smooth((z - .74) / .19))

        # Loose woven pants taper and bunch above the shin wraps.
        profile = [
            (.56, .233, .007, .086, .096), (.59, .230, .012, .101, .105),
            (.62, .236, .005, .112, .114), (.66, .242, .011, .126, .115),
            (.69, .236, .023, .106, .117), (.73, .225, .027, .134, .132),
            (.78, .222, .035, .123, .136), (.85, .212, .028, .131, .138),
            (.94, .203, .016, .133, .139), (1.03, .191, .004, .141, .141),
            (1.13, .178, -.008, .144, .146), (1.22, .165, -.011, .141, .147),
            (1.29, .143, -.011, .132, .133), (1.36, .133, -.016, .112, .121),
        ]
        previous = None
        count = 24
        for i, (z, x, y, rx, ry) in enumerate(profile):
            row = []
            for j in range(count):
                a = TAU * j / count
                fold = .008 * math.cos(3 * a + z * 11) + .007 * math.sin(7 * a - i * .58)
                if i < 8:
                    fold += .008 * math.sin(4 * a + i * 1.42)
                point = (side * x + (rx + fold) * math.cos(a),
                         y + (ry + fold) * math.sin(a), z)
                row.append(shell.vertex(point, PANTS, trouser_weight(point), 1.0 + fold * 14.0))
            if previous:
                shell.join(previous, row)
            else:
                shell.faces.append(tuple(reversed(row)))
            previous = row
        shell.faces.append(tuple(previous))
        # Wear lines give direction to the long thigh creases.
        for offset, depth in [(-.058, .136), (.040, .144)]:
            points = [(side * (x + offset), y + depth + .004, z)
                      for z, x, y, *_ in profile[7:12]]
            details.strip(points, [.004, .016, .010, .006, .001], "#39373F", trouser_weight, .004)

        shin_profile = [
            (.104, .259, -.016, .063, .077), (.158, .255, -.018, .065, .073),
            (.206, .252, -.023, .066, .070), (.292, .246, -.025, .070, .075),
            (.397, .241, -.021, .080, .086), (.500, .236, -.012, .090, .095),
            (.584, .233, .002, .091, .097), (.615, .230, .004, .085, .097),
        ]
        shell.tube([(side * x, y, z, rx, ry) for z, x, y, rx, ry in shin_profile], WRAP,
                   lambda p: blend(foot, calf, smooth((p.z - .108) / .12)), 18, .09)
        def boot_contour(z):
            x, y, rx, ry = sample(shin_profile, z)
            return side * x, y, rx, ry

        spiral(details, boot_contour, (.177, .583), 5.0, .087, "#33303A", calf, .5 * side)
        spiral(details, boot_contour, (.178, .573), -3.4, .011, "#25232B", calf, .5 * side)

        # A toe box that follows the foot, with a split-toe seam and a beveled sole.
        foot_rows = [
            (.012, .259, .071, .088, .160), (.022, .259, .071, .098, .174),
            (.040, .259, .069, .100, .176), (.057, .259, .066, .096, .168),
            (.081, .257, .059, .089, .154), (.107, .256, .036, .079, .137),
            (.134, .258, .006, .069, .110), (.164, .255, -.016, .065, .076),
        ]
        shoe = [(side * (x + .23 * max(0, y)), y, z, rx, ry) for z, x, y, rx, ry in foot_rows]
        shell.tube(shoe[:4], "#211F25", foot, 20, .04)
        shell.tube(shoe[3:], "#343139", foot, 20, .10)
        details.strip([(side * .256, .230, .056), (side * .251, .206, .082),
                       (side * .248, .166, .112), (side * .249, .109, .131)],
                      [.004, .004, .003, .001], INK, foot, front=UP)


def build_hood(shell, details):
    rows = []
    # The hood is down. Its roll rises at the nape and folds to a front V.
    for level, (rx, front_r, back_r, height, front_drop, back_drop) in enumerate([
        (.092, .092, .091, 2.019, .062, -.014),
        (.120, .129, .125, 2.001, .075, -.014),
        (.164, .165, .168, 1.976, .112, -.006),
        (.200, .190, .207, 1.940, .153, .018),
        (.234, .201, .237, 1.893, .132, .083),
        (.235, .201, .227, 1.875, .107, .154),
        (.211, .174, .192, 1.861, .078, .165),
    ]):
        ring = []
        for j in range(40):
            a = TAU * j / 40
            y = math.sin(a)
            front, back = max(0.0, y), max(0.0, -y)
            z = height - front_drop * front ** 2.4 - back_drop * back ** 1.9
            z += .012 * math.sin(3 * a + level * .70)
            point = (rx * math.cos(a), front_r * front - back_r * back, z)
            shade = 1.0 + .15 * math.cos(3 * a - level * .83) + .07 * (level % 2)
            ring.append(shell.vertex(point, "#34323A", "Chest", shade))
        if rows:
            shell.join(ring, rows[-1])
        rows.append(ring)
    for side in (-1, 1):
        details.strip([(side * .188, -.139, 1.942), (side * .139, -.194, 1.877),
                       (side * .083, -.228, 1.790), (0, -.222, 1.728)],
                      [.001, .004, .004, .001], "#524B52", "Chest", front=-FRONT)


def build_waist(shell, details):
    loops = []
    for i, (z, rx, ry) in enumerate([(1.333, .216, .140), (1.353, .223, .151),
                                     (1.383, .229, .157), (1.421, .222, .154),
                                     (1.456, .219, .145), (1.485, .223, .141)]):
        ring = []
        for j in range(36):
            a = TAU * j / 36
            ripple = math.sin(a * 3.0 + i * 1.29)
            point = (math.cos(a) * (rx + .005 * ripple),
                     math.sin(a) * (ry + .005 * ripple), z + .022 * math.sin(a + i * .88))
            ring.append(shell.vertex(point, "#38343A", "Pelvis", .78 + .23 * (i % 2) + .08 * ripple))
        if loops:
            shell.join(loops[-1], ring)
        loops.append(ring)

    # Four separate overlapping fabric panels, with deliberately uneven hems.
    for panel, (center, span, hem) in enumerate([(1.00, .75, 1.112), (2.22, .64, 1.148),
                                                (4.15, .89, 1.142), (5.37, .91, 1.127)]):
        prev = None
        for i in range(6):
            t = i / 5
            row = []
            for j in range(13):
                u = j / 12 * 2 - 1
                a = center + u * span * (.81 + .19 * t) + .16 * t
                fold = .012 * math.sin(u * math.pi * 2.1 + t * 1.2)
                rx, ry = .230 + .083 * t + fold, .156 + .018 * t + fold
                z = (1.365 + .010 * u) * (1 - t) + (hem + .062 * u) * t
                point = (rx * math.cos(a), ry * math.sin(a), z)
                leg = "Thigh_L" if point[0] < 0 else "Thigh_R"
                weight = blend("Pelvis", leg, t * t * .54)
                row.append(details.vertex(point, CLOTH, weight, 1.06 + 10 * fold + .04 * (panel % 2)))
            if prev:
                details.join(prev, row, False)
            prev = row

    shell.tube([(-.145, .157, 1.462, .034, .024), (-.171, .179, 1.415, .050, .036),
                (-.182, .168, 1.369, .035, .026)], "#3B353B", "Pelvis", 12, .12)
    for index, (end, shift) in enumerate([(.986, -.061), (.851, -.104)]):
        points = [(-.170, .185, 1.431), (-.190 + shift * .2, .195, 1.314),
                  (-.214 + shift * .4, .205, 1.183), (-.216 + shift * .74, .190, 1.065),
                  (-.222 + shift, .168, end)]
        details.strip(points, [.025, .043, .059, .057, .002], "#3B383E" if index == 0 else "#2C2A32",
                      lambda p: blend("Pelvis", "SashTail", smooth((1.405 - p.z) / .27)), .022)


def build_face(shell, skin, details):
    last = None
    for z, width, depth, offset in HEAD:
        row = []
        for j in range(44):
            a = TAU * j / 44
            x = width * math.cos(a)
            y = face_depth(x, z) if math.sin(a) >= 0 else offset + depth * math.sin(a)
            shade = 1.02 + .055 * math.sin(a) - .044 * abs(math.cos(a))
            row.append(skin.vertex((x, y, z), SKIN, "Head", shade))
        if last:
            skin.join(last, row)
        else:
            skin.faces.append(tuple(reversed(row)))
        last = row
    skin.faces.append(tuple(last))
    for side in (-1, 1):
        skin.tube([(side * .128, .015, 2.125, .012, .017),
                   (side * .152, .009, 2.158, .021, .023),
                   (side * .153, .002, 2.190, .019, .025),
                   (side * .141, -.001, 2.204, .009, .012)], SKIN, "Head", 10, .09)
        details.strip([(side * .146, .026, 2.139), (side * .161, .030, 2.174),
                       (side * .152, .029, 2.194)],
                      [.002, .005, .001], "#8C5B52", "Head", .001)
        build_eye(details, side)

    shell.tube([(0.0, -.010, 1.912, .090, .084), (0, -.011, 1.961, .085, .088),
                (0.0, -.015, 2.020, .105, .103), (0.0, -.018, 2.057, .104, .109)],
               "#24222A", "Head", 20)
    # Fit the mask to the jaw at every height, including its pointed nose bridge.
    prev = None
    for i in range(15):
        t = i / 14
        ring = []
        for j in range(43):
            a = (j / 42 * 2 - 1) * 1.79
            s, c = math.sin(a), math.cos(a)
            top = 2.174 + .015 * math.exp(-(s / .24) ** 2) + .021 * abs(s) ** 2.1
            bottom = 1.973 + .019 * abs(s)
            z = bottom * (1 - t) + top * t
            rx, depth, dy = sample(HEAD, z)
            x = (rx + .008) * s
            y = face_depth(rx * s, z) + .013 if c >= 0 else dy + (depth + .010) * c
            y += .006 * math.sin(math.pi * t) * math.cos(3.2 * a + t * 2.1)
            ring.append(details.vertex((x, y, z), "#25242D", "Head",
                                       .97 + .12 * math.cos(3 * a + 2.5 * t) + .10 * t))
        if prev:
            details.join(prev, ring, False)
        prev = ring
    for side in (-1, 1):
        points = [(side * x, face_depth(x, z) + lift, z) for x, z, lift in
                  [(0, 2.169, .020), (.031, 2.152, .021), (.065, 2.128, .019),
                   (.087, 2.106, .018)]]
        details.strip(points, [.001, .003, .004, .001], "#3E3943", "Head", .002)


def build_eye(details, side):
    # Contours sit on the cheek surface. The iris is clipped to the lower lid.
    eye = [
        (.025, 2.196, 2.196), (.036, 2.213, 2.194),
        (.052, 2.221, 2.193), (.071, 2.225, 2.195),
        (.088, 2.229, 2.203), (.103, 2.232, 2.212), (.117, 2.237, 2.235),
    ]

    def point(x, z, lift):
        return (side * x, face_depth(x, z) + lift, z)

    previous = None
    for x, high, low in eye:
        ring = [details.vertex(point(x, z, .005), "#E8E0CE", "Head") for z in (low, high)]
        if previous:
            details.join(previous, ring, False)
        previous = ring
    for index, (center, half_x, half_z, color, lift) in enumerate([
        ((.069, 2.210), .020, .021, "#363D35", .007),
        ((.069, 2.210), .016, .019, "#71825E", .009),
        ((.069, 2.214), .007, .014, "#21261F", .011),
        ((.063, 2.219), .004, .004, "#E8E4D6", .013),
    ]):
        x, z = center
        disk = []
        for j in range(19):
            angle = TAU * j / 19
            xx = x + half_x * math.cos(angle)
            high, low = sample(eye, xx)
            zz = min(high - .001, max(low + .001, z + half_z * math.sin(angle)))
            disk.append(details.vertex(point(xx, zz, lift), color, "Head"))
        center_vertex = details.vertex(point(x, z, lift), color, "Head", .88 if index == 1 else 1)
        details.faces.extend((center_vertex, a, b) for a, b in zip(disk, disk[1:] + disk[:1]))

    details.strip([point(x, high, .010) for x, high, _ in eye],
                  [.001, .003, .004, .004, .004, .005, .001], "#1B171C", "Head")
    details.strip([point(x, low, .007) for x, _, low in eye],
                  [.001, .002, .002, .002, .002, .001, .001], "#65443E", "Head")
    details.strip([point(x, z, .007) for x, z in [(.024, 2.223), (.053, 2.241),
                                                 (.078, 2.249), (.106, 2.251), (.122, 2.247)]],
                  [.002, .006, .007, .005, .001], "#231D22", "Head")


def build_headband(shell, details):
    prev = None
    for z, lift in [(2.260, .002), (2.267, .010), (2.309, .011), (2.319, .004)]:
        row = []
        for j in range(40):
            a = TAU * j / 40
            x = .143 * math.cos(a)
            y = face_depth(x, z) + lift if math.sin(a) >= 0 else (.132 + lift) * math.sin(a)
            row.append(shell.vertex((x, y, z + .009 * math.cos(a)), "#3D363B", "Head",
                                    .91 + .07 * math.sin(3 * a + z * 70)))
        if prev:
            shell.join(prev, row)
        prev = row

    # The plaque follows the forehead instead of floating flat over the bangs.
    previous = None
    for x in [-.080, -.075, -.054, -.027, 0, .027, .054, .075, .080]:
        edge = 1.0 - smooth((abs(x) - .073) / .010) * .23
        row = []
        for v in (-1.0, -.87, .87, 1.0):
            z = 2.286 + .027 * v * edge + x * .080
            y = face_depth(x, z) + .013 + .004 * (1 - abs(v))
            row.append(details.vertex((x, y, z), "#49434A", "Head", .83 if abs(v) == 1.0 else 1.08))
        if previous:
            details.join(previous, row, False)
        previous = row

    # Engraving contours are authored from the two glyphs on the sheet.
    glyphs = [
        # 黒
        [[(1, 1), (7, 1), (7, 6), (1, 6), (1, 1)], [(1, 3.5), (7, 3.5)],
         [(4, 1), (4, 10)], [(1, 8), (7, 8)], [(0, 10), (8, 10)],
         [(1.5, 11.7), (.8, 13.0)], [(3.5, 11.8), (3.7, 13)],
         [(5.3, 11.7), (5.7, 13)], [(7, 11.7), (8, 13)]],
        # 龍
        [[(2.7, .7), (3.4, 2)], [(.2, 2.6), (6.2, 2.6)],
         [(1.6, 3.2), (2.2, 4.9)], [(5.2, 3.1), (4.7, 4.8)], [(.1, 5.2), (6.1, 5.2)],
         [(1.1, 13), (1.1, 6.9), (5.5, 6.9), (5.5, 12.7), (4.6, 13.2)],
         [(1.2, 8.9), (5.2, 8.9)], [(1.2, 10.8), (5.2, 10.8)],
         [(7.6, 1), (7.6, 5.2), (11, 5.2), (11, 2.5), (7.7, 2.5)],
         [(7.6, 6.8), (7.6, 11.8), (8.6, 13), (11.8, 13), (12.2, 11.6)],
         [(7.7, 7.0), (11.4, 7.0)], [(7.7, 9.0), (11.4, 9.0)], [(7.7, 11), (11.4, 11)]],
    ]
    for origin, strokes in zip((-.055, -.009), glyphs):
        for stroke in strokes:
            points = []
            for a, b in stroke:
                x, z = -(origin + a * .0036), 2.310 - b * .0032
                points.append((x, face_depth(x, z) + .0187, z + x * .080))
            details.strip(points, [.00105] * len(points), "#A69B90", "Head", sections=1)

    # The silk tails exit the knot to the same side in both views.
    shell.tube([(.038, -.118, 2.287, .021, .013), (.076, -.146, 2.286, .037, .024),
                (.108, -.142, 2.277, .027, .019)], "#302D34", "Head", 10)
    paths = [
        [(.080, -.148, 2.291), (.183, -.176, 2.301), (.282, -.198, 2.276),
         (.391, -.229, 2.230), (.489, -.263, 2.212), (.558, -.300, 2.201)],
        [(.076, -.147, 2.279), (.164, -.184, 2.245), (.257, -.207, 2.202),
         (.333, -.231, 2.166), (.415, -.257, 2.103), (.486, -.304, 2.078)],
    ]
    for i, path in enumerate(paths):
        details.strip(path, [.019, .026, .025, .021, .022, .002],
                      "#28252F" if i == 0 else "#36313A",
                      lambda p: blend("Head", f"Ribbon_{i}", smooth((p.x - .089) / .14)), .006)


def hair_lock(shell, points, color, width):
    rows = [(x, y, z, width * w, width * d) for (x, y, z), (w, d) in zip(
        points, [(1.0, .40), (.99, .49), (.60, .36), (.075, .09)])]
    shell.tube(rows, color, "Head", 8, .20)


def build_hair(shell, details):
    rng = random.Random(87)
    prev = None
    for t in (0.0, .16, .34, .50, .67, .81, .93, 1.0):
        row = []
        for j in range(32):
            a = TAU * j / 32
            front = max(0, math.sin(a))
            bottom = 2.073 + .243 * front ** .72 + .055 * abs(math.cos(a))
            z = bottom * (1 - t) + 2.437 * t
            rx, ry, dy = sample(HEAD, min(z, 2.403))
            factor = 1.11 + .05 * math.sin(5 * a - t * 2)
            factor *= 1.0 - .52 * smooth((t - .92) / .08)
            p = ((rx * factor + .008) * math.cos(a), dy + (ry * factor + .009) * math.sin(a), z)
            row.append(shell.vertex(p, HAIR, "Head", 1.0 + .11 * math.sin(a * 8 + t * 3)))
        if prev:
            shell.join(prev, row)
        prev = row
    shell.faces.append(tuple(prev))

    for layer, count in enumerate((12, 13, 8)):
        for j in range(count):
            a = TAU * (j + .21 * layer) / count + rng.uniform(-.14, .14)
            forward = math.sin(a)
            if layer == 0 and forward > .58:
                continue
            z = (2.268, 2.346, 2.403)[layer] + rng.uniform(-.016, .021)
            direction = .48 if j % 3 else -.36
            radius = (.130, .118, .091)[layer]
            length = rng.uniform(.052, .108)
            drop = -.084 if layer == 0 else (.032 if layer == 1 else .081)
            tip = radius + length * (1.1 if layer < 2 else .74)
            path = []
            for t in (0.0, .31, .64, 1.0):
                angle = a + direction * t ** 1.5
                r = radius * (1 - t) + tip * t
                height = z + .025 * math.sin(math.pi * t) + drop * t
                path.append((r * math.cos(angle), r * .94 * math.sin(angle) - .019, height))
            hair_lock(shell, path, (HAIR, "#2B2931", "#292831")[j % 3], rng.uniform(.025, .045))

    bangs = [
        [(-.043, .075, 2.420), (-.097, .120, 2.379), (-.115, .154, 2.310), (-.127, .143, 2.247)],
        [(-.034, .093, 2.438), (-.067, .136, 2.402), (-.089, .160, 2.350), (-.104, .163, 2.310)],
        [(.010, .065, 2.430), (-.017, .111, 2.402), (-.041, .146, 2.369), (-.063, .160, 2.323)],
        [(.029, .059, 2.451), (.024, .110, 2.424), (.010, .138, 2.391), (-.026, .154, 2.349)],
        [(.029, .071, 2.441), (.060, .117, 2.403), (.078, .144, 2.350), (.074, .141, 2.286)],
        [(.052, .043, 2.411), (.090, .104, 2.372), (.122, .137, 2.315), (.108, .144, 2.236)],
        [(.077, .039, 2.402), (.119, .082, 2.357), (.146, .109, 2.296), (.149, .103, 2.242)],
    ]
    for i, path in enumerate(bangs):
        hair_lock(shell, path, HAIR if i % 2 == 0 else "#2C2933", .032 + (i % 3) * .004)
        ridge = [(x, y + shift, z) for (x, y, z), shift in zip(path[1:], (.018, .013, .0015))]
        details.strip(ridge, [.007, .008, .001], HAIR_GLINT, "Head", .002)
    for path, width in [
        ([(-.075, -.051, 2.399), (-.059, -.049, 2.451), (-.031, -.047, 2.490), (-.042, -.039, 2.520)], .032),
        ([(.006, -.059, 2.409), (.025, -.046, 2.462), (.067, -.051, 2.487), (.101, -.054, 2.512)], .037),
        ([(.052, -.071, 2.407), (.092, -.085, 2.444), (.129, -.084, 2.459), (.174, -.080, 2.461)], .037),
    ]:
        hair_lock(shell, path, "#2B2832", width)


def build_swords(shell, details):
    for index, sign in enumerate((-1, 1)):
        handle = Vector((sign * .319, -.243 - .061 * index, 1.934))
        tip = Vector((-sign * .346, -.243 - .061 * index, 1.053 + .037 * index))
        axis = (handle - tip).normalized()
        tangent = Vector((axis.z, 0, -axis.x))
        length = (handle - tip).length

        def segment(profile, color, count=12, square=False, grain=.07):
            points = [(*tuple(tip + axis * along + tangent * (sign * bend)), width, depth)
                      for along, bend, width, depth in profile]
            shell.tube(points, color, "Chest", count, grain, square)

        segment([(0.0, .023, .020, .021), (.039, .024, .029, .025),
                 (.258, .019, .032, .026), (.50, .010, .034, .026),
                 (.80, .002, .032, .024), (length - .044, 0, .031, .026)],
                "#34323A" if index == 0 else "#292830", square=True)
        segment([(0.0, .023, .021, .022), (.017, .024, .029, .026),
                 (.040, .024, .031, .027)], METAL, square=True)
        segment([(length - .110, 0, .033, .027), (length - .096, 0, .035, .030),
                 (length - .069, 0, .035, .030), (length - .058, 0, .031, .026)],
                "#665C54", square=True)
        segment([(length - .048, 0, .030, .025), (length - .011, 0, .030, .025)],
                "#4D4442", square=True)
        segment([(length - .016, 0, .039, .031), (length - .003, 0, .057, .038),
                 (length + .010, 0, .057, .038), (length + .025, 0, .039, .031)], METAL, 18)
        segment([(length + .022, 0, .024, .021), (length + .065, 0, .023, .020),
                 (length + .172, .003, .022, .020), (length + .222, .006, .025, .021)],
                "#312C32", square=True)
        segment([(length + .217, .006, .024, .021), (length + .232, .006, .023, .021),
                 (length + .239, .006, .019, .018)], METAL, square=True)

        # The diamond openings in the hilt wrapping read from either camera.
        for i in range(5):
            where = handle + axis * (.053 + .035 * i)
            for face in (-1, 1):
                where_face = where + FRONT * (.0215 * face)
                diamond = [where_face + axis * .011, where_face + tangent * .011,
                           where_face - axis * .011, where_face - tangent * .011]
                details.faces.append(tuple(details.vertex(p, "#A39585", "Chest") for p in diamond))

        for face in (-1, 1):
            edge = [tip + axis * f + tangent * (sign * bend - .021) + FRONT * (.027 * face)
                    for f, bend in [(.049, .024), (.258, .019), (.50, .010), (.80, .002), (length - .117, 0)]]
            details.strip(edge, [.0025, .004, .003, .0025, .001], "#53505A", "Chest")
    # Cross-sheath retaining straps with a charcoal sash knot at the small of the back.
    for sign in (-1, 1):
        details.strip([(sign * .232, -.169, 1.682), (sign * .142, -.273, 1.606),
                       (0.0, -.337, 1.524), (-sign * .163, -.283, 1.453),
                       (-sign * .213, -.173, 1.395)], [.017, .024, .028, .025, .013],
                      "#403841", "Chest", .009, front=-FRONT)


def build_vials(shell):
    for i, (x, y, size) in enumerate([(-.201, .182, .131), (-.252, .171, .149), (-.292, .137, .106)]):
        top = 1.430 - i * .017
        for lo, hi, radius, color in [
            (.00, .10, .022, METAL), (.09, .73, .022, "#41616A"),
            (.24, .32, .024, "#A09885"), (.73, .85, .024, METAL),
            (.84, .93, .014, "#383238"), (.92, 1.0, .017, "#90847A"),
        ]:
            shell.tube([(x - .022, y, top - size + size * lo, radius * .94, radius * .94),
                        (x - .022, y, top - size + size * hi, radius, radius)], color, "Pelvis", 10, .13)


def make_rig():
    data = bpy.data.armatures.new("ShinobiSkeleton")
    rig = bpy.data.objects.new("ShinobiRig", data)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")

    def bone(name, head, tail, parent=None):
        item = data.edit_bones.new(name)
        item.head, item.tail = head, tail
        if parent:
            item.parent = data.edit_bones[parent]

    bone("Pelvis", (0, 0, 1.272), (0, 0, 1.46))
    bone("Chest", (0, 0, 1.46), (0, -.009, 1.93), "Pelvis")
    bone("Head", (0, -.010, 1.93), (0, -.004, 2.38), "Chest")
    for sign, suffix in [(-1, "L"), (1, "R")]:
        shoulder, elbow, wrist = (sign * .251, 0, 1.808), (sign * .420, .024, 1.493), (sign * .478, .066, 1.215)
        hip, knee, ankle = (sign * .150, -.004, 1.272), (sign * .220, .029, .818), (sign * .258, -.017, .162)
        bone(f"UpperArm_{suffix}", shoulder, elbow, "Chest")
        bone(f"Forearm_{suffix}", elbow, wrist, f"UpperArm_{suffix}")
        bone(f"Hand_{suffix}", wrist, (sign * .497, .075, 1.106), f"Forearm_{suffix}")
        bone(f"Thigh_{suffix}", hip, knee, "Pelvis")
        bone(f"Calf_{suffix}", knee, ankle, f"Thigh_{suffix}")
        bone(f"Foot_{suffix}", ankle, (sign * .258, .165, .045), f"Calf_{suffix}")
    bone("Ribbon_0", (.082, -.149, 2.291), (.343, -.218, 2.252), "Head")
    bone("Ribbon_1", (.079, -.148, 2.279), (.313, -.228, 2.176), "Head")
    bone("SashTail", (-.180, .174, 1.413), (-.231, .191, 1.113), "Pelvis")
    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


def preview(path, objects):
    path.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 8
    scene.cycles.use_denoising = False
    scene.render.resolution_x = 520
    scene.render.resolution_y = 820
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = "Standard"
    scene.world.color = (.63, .61, .58)
    for obj in objects:
        # Approximate the in-game cel ramp without a display server.
        mat = obj.data.materials[0]
        nodes, links = mat.node_tree.nodes, mat.node_tree.links
        geom = nodes.new("ShaderNodeNewGeometry")
        dot = nodes.new("ShaderNodeVectorMath")
        dot.operation = "DOT_PRODUCT"
        dot.inputs[1].default_value = (-.48, .47, .74)
        links.new(geom.outputs["Normal"], dot.inputs[0])
        ramp = nodes.new("ShaderNodeMapRange")
        ramp.interpolation_type = "SMOOTHSTEP"
        links.new(dot.outputs["Value"], ramp.inputs[0])
        ramp.inputs["From Min"].default_value = .15
        ramp.inputs["From Max"].default_value = .27
        ramp.inputs["To Min"].default_value = .65
        ramp.inputs["To Max"].default_value = 1.24
        multiply = nodes.new("ShaderNodeVectorMath")
        multiply.operation = "SCALE"
        links.new(nodes.get("Color Attribute").outputs["Color"], multiply.inputs[0])
        links.new(ramp.outputs[0], multiply.inputs["Scale"])
        emission = nodes.new("ShaderNodeEmission")
        links.new(multiply.outputs[0], emission.inputs["Color"])
        links.new(emission.outputs[0], nodes.get("Material Output").inputs["Surface"])
    backdrop = scene.world.node_tree.nodes.get("Background")
    backdrop.inputs["Color"].default_value = (.78, .75, .70, 1)
    backdrop.inputs["Strength"].default_value = 1.0
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 2.72
    scene.camera = camera
    for title, position in [("front", (0.0, 7.0, 1.31)), ("back", (0.0, -7.0, 1.31)),
                            ("quarter", (3.8, 5.5, 1.72))]:
        camera.location = position
        camera.rotation_euler = (Vector((0.0, 0.0, 1.265)) - camera.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(path / (title + ".png"))
        bpy.ops.render.render(write_still=True)


def main():
    args = argparse.ArgumentParser()
    args.add_argument("--preview", type=Path)
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    options = args.parse_args(argv)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    shell, skin, details = (PaintedMesh(name) for name in ("Costume", "Skin", "Details"))
    build_jacket(shell, skin, details)
    build_legs(shell, details)
    build_hood(shell, details)
    build_waist(shell, details)
    build_face(shell, skin, details)
    build_headband(shell, details)
    build_hair(shell, details)
    build_swords(shell, details)
    build_vials(shell)
    rig = make_rig()
    objects = [layer.create(rig) for layer in (shell, skin, details)]
    destination = ROOT / "characters" / "art" / "shinobi_black.glb"
    bpy.ops.export_scene.gltf(filepath=str(destination), export_format="GLB",
                             export_animations=False, export_vertex_color="MATERIAL")
    print(f"Shinobi Black: {sum(len(obj.data.vertices) for obj in objects)} vertices, "
          f"{len(rig.data.bones)} bones -> {destination}")
    if options.preview:
        preview(options.preview, objects)


if __name__ == "__main__":
    main()
