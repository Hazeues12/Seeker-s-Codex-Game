"""Build the three low-cost, skinned Magnara crowd models.

Run from the project root with:
    blender -b --factory-startup --python tools/art/build_townsfolk.py
"""

import math
from pathlib import Path
import sys

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_shinobi_black import PaintedMesh, TAU, blend, sample, smooth

ROOT = Path(__file__).resolve().parents[2]
WOOL = "#D6D1C8"
LINEN = "#ECE6D9"
LEATHER = "#4B4144"
TROUSERS = "#525662"


class CitizenMesh(PaintedMesh):
    # Store the paint region per vertex, then export it in the mesh UVs.
    region = "fixed"
    MASK = {"coat": .10, "trim": .30, "skin": .50, "hair": .70, "fixed": .90}

    def vertex(self, point, color, weights, shade=1.0):
        index = super().vertex(point, color, weights, shade)
        self.colors[index] = (*self.colors[index][:3], self.MASK[self.region])
        return index


def height(z, form):
    if form == "child":
        return min(z, .96) * .66 + max(0, min(z, 1.69) - .96) * .61 + max(0, z - 1.69) * .88
    return z * (.971 if form == "woman" else 1.0)


def build_rig(form, shoulder, hip):
    data = bpy.data.armatures.new(form.title() + "Skeleton")
    rig = bpy.data.objects.new(form.title() + "Rig", data)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")

    def bone(name, start, end, parent=None):
        item = data.edit_bones.new(name)
        item.head = (*start[:2], height(start[2], form))
        item.tail = (*end[:2], height(end[2], form))
        if parent:
            item.parent = data.edit_bones[parent]

    bone("Pelvis", (0, 0, .99), (0, 0, 1.15))
    bone("Chest", (0, 0, 1.15), (0, 0, 1.65), "Pelvis")
    bone("Head", (0, 0, 1.65), (0, 0, 2.05), "Chest")
    for side, suffix in [(-1, "L"), (1, "R")]:
        top = (side * shoulder, 0, 1.506)
        elbow = (side * (shoulder + .085), .014, 1.265)
        wrist = (side * (shoulder + .125), .033, 1.025)
        knee = (side * hip * 1.12, .018, .504)
        bone("Upper_" + suffix, top, elbow, "Chest")
        bone("Lower_" + suffix, elbow, wrist, "Upper_" + suffix)
        bone("Thigh_" + suffix, (side * hip, 0, .99), knee, "Pelvis")
        bone("Shin_" + suffix, knee, (side * hip * 1.25, 0, .135), "Thigh_" + suffix)
    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


def chest_weight(p):
    return blend("Pelvis", "Chest", smooth((p[2] - 1.07) / .25))


def jacket(mesh, form, shoulder):
    # The four middle rings carry the fitted shoulder openings for the sleeves.
    woman = form == "woman"
    waist = .151 if woman else (.151 if form == "child" else .180)
    hip = .223 if woman else (.208 if form == "child" else .215)
    rings = [
        (.87, hip, .146), (.94, hip, .140), (1.05, waist + .022, .121),
        (1.13, waist, .111), (1.22, waist + .018, .116),
        (1.30, shoulder * .85, .129), (1.37, shoulder * .97, .134),
        (1.43, shoulder + .006, .133), (1.49, shoulder + .008, .120),
        (1.55, shoulder - .011, .106), (1.59, shoulder - .044, .091),
        (1.64, .086, .073),
    ]
    count = 24
    low, high, width = 6, 10, 2
    profile = []
    mesh.region = "coat"
    for i, (z, rx, ry) in enumerate(rings):
        row = []
        for j in range(count):
            a = j * TAU / count
            fold = .004 * math.sin(a * 4 + i * .87)
            p = ((rx + fold) * math.cos(a), (ry + fold) * math.sin(a), z)
            row.append(mesh.vertex(p, WOOL, chest_weight(p), 1 + 17 * fold))
        if profile:
            skip = ()
            if low < i <= high:
                skip = {(side + j) % count for side in (0, count // 2) for j in range(-width, width)}
            mesh.join(profile[-1], row, skip=skip)
        profile.append(row)
    mesh.faces += [tuple(reversed(profile[0])), tuple(profile[-1])]

    for side, suffix in [(-1, "L"), (1, "R")]:
        middle = 0 if side == 1 else count // 2
        left, right = middle - width, middle + width
        border = [(low, j) for j in range(left, right + 1)]
        border += [(i, right) for i in range(low + 1, high + 1)]
        border += [(high, j) for j in range(right - 1, left - 1, -1)]
        border += [(i, left) for i in range(high - 1, low, -1)]
        previous = [profile[i][j % count] for i, j in border]
        angles = [math.atan2((mesh.points[v][2] - 1.48) / .11, mesh.points[v][1] / .065)
                  for v in previous]
        sleeve = [
            (.037, 1.470, .076, .077), (.069, 1.400, .073, .074),
            (.082, 1.320, .068, .062), (.087, 1.264, .064, .061),
            (.106, 1.182, .056, .052), (.124, 1.050, .048, .050),
            (.125, 1.018, .046, .050),
        ]
        upper, lower = "Upper_" + suffix, "Lower_" + suffix
        for i, (x, z, ry, rz) in enumerate(sleeve):
            mesh.region = "coat" if i < 5 else "trim"
            row = []
            for a in angles:
                sine = math.sin(a)
                p = (side * (shoulder + x + rz * sine * .88),
                     .03 * i / 6 + ry * math.cos(a), z + rz * sine * .48)
                weight = blend(upper, lower, smooth((1.35 - z) / .16))
                if i < 2:
                    weight = blend("Chest", upper, .65 + .30 * i)
                row.append(mesh.vertex(p, WOOL, weight, .98 + .06 * math.sin(3 * a + i)))
            mesh.join(previous, row)
            previous = row
        mesh.faces.append(tuple(previous))
        mesh.region = "skin"
        hand = side * (shoulder + .129)
        mesh.tube([(hand, .033, 1.041, .035, .041), (hand, .036, 1.007, .044, .033),
                   (hand - side * .005, .046, .956, .034, .024),
                   (hand - side * .013, .056, .937, .018, .018)], "#FFF2E3", lower, 8)

    mesh.region = "trim"
    mesh.tube([(0, 0, 1.065, waist + .025, .129), (0, 0, 1.086, waist + .027, .128),
               (0, 0, 1.114, waist + .018, .123)], LINEN, "Pelvis", 20)
    if woman:
        mesh.region = "coat"
        # Overlapping panels give the fitted wrap coat a separate silhouette at distance.
        for side in (-1, 1):
            previous = None
            for row_index in range(5):
                t = row_index / 4
                row = []
                for j in range(13):
                    u = j / 12
                    a = (u - .07) * math.pi * 1.16 + (math.pi if side < 0 else 0)
                    fold = .010 * math.sin(6.5 * a + t * .6)
                    x = (.213 + .055 * t + fold) * math.cos(a)
                    y = (.143 + .034 * t + fold) * math.sin(a)
                    z = 1.090 - (.400 - .067 * u) * t
                    bone = "Thigh_L" if x < 0 else "Thigh_R"
                    row.append(mesh.vertex((x, y, z), WOOL,
                        blend("Pelvis", bone, .74 * t * t), 1.0 + 9 * fold))
                if previous:
                    mesh.join(row, previous, False)
                previous = row
        mesh.region = "trim"
        mesh.strip([(.095, .105, 1.617), (.114, .134, 1.523), (.077, .148, 1.407),
                    (-.012, .146, 1.277), (-.103, .120, 1.150)],
                   [.026, .031, .031, .027, .017], LINEN, chest_weight, .006, 2)
    else:
        mesh.region = "trim"
        for side in (-1, 1):
            mesh.strip([(side * .083, .065, 1.625), (side * .107, .116, 1.558),
                        (side * .047, .137, 1.471), (side * .017, .141, 1.329)],
                       [.025, .034, .030, .008], LINEN, "Chest", .008, 2)
        mesh.region = "fixed"
        mesh.strip([(0.0, .136, 1.380), (0, .127, 1.251), (0, .124, 1.136)],
                   [.004, .004, .004], "#626069", chest_weight, .004, 2)


def legs(mesh, form, hip):
    for side, suffix in [(-1, "L"), (1, "R")]:
        thigh, shin = "Thigh_" + suffix, "Shin_" + suffix

        def leg_weight(p):
            if p[2] > .85:
                return blend(thigh, "Pelvis", smooth((p[2] - .85) / .22))
            return blend(shin, thigh, smooth((p[2] - .424) / .165))

        mesh.region = "fixed"
        mesh.tube([(side * hip * stretch, y, z, xw, yw) for z, stretch, y, xw, yw in [
            (.135, 1.24, .000, .068, .071), (.225, 1.22, -.002, .071, .076),
            (.361, 1.18, .008, .080, .087), (.477, 1.13, .019, .086, .092),
            (.525, 1.12, .021, .091, .097), (.610, 1.09, .009, .098, .102),
            (.755, 1.04, .003, .099, .101), (.858, .98, .000, .085, .100),
            (.940, .91, -.003, .075, .098), (1.052, .77, -.008, .070, .091),
        ]], TROUSERS, leg_weight, 12, .11)
        mesh.tube([(side * hip * 1.24, .062, .013, .081, .122),
                   (side * hip * 1.24, .061, .040, .086, .129),
                   (side * hip * 1.24, .052, .068, .083, .122),
                   (side * hip * 1.24, .020, .114, .072, .093),
                   (side * hip * 1.24, 0, .166, .069, .072),
                   (side * hip * 1.24, 0, .188, .069, .072)], LEATHER, shin, 12, .09)


def head(mesh, form):
    jaw = {"man": .112, "woman": .084, "child": .095}[form]
    width = 1.04 if form == "child" else 1.0
    shape = [(1.689,.050,.061),(1.735,jaw,.088),(1.792,.113,.104),
             (1.850,.128,.113),(1.902,.132,.118),(1.943,.130,.117),
             (1.985,.124,.112),(2.030,.107,.101),(2.067,.075,.074),(2.086,.008,.012)]
    shape = [(z, rx * width, ry * width) for z, rx, ry in shape]

    def face(x, z):
        rx, ry = sample(shape, z)
        nose = .018 * math.exp(-(x / .027) ** 2 - ((z - 1.868) / .020) ** 2)
        return ry * max(0, 1 - (x / rx) ** 2) ** .40 + nose

    mesh.region = "skin"
    mesh.tube([(0, 0, 1.592, .065, .065), (0, 0, 1.659, .064, .070),
               (0, 0, 1.741, .070, .075)], "#FFF3E8", "Head", 12)
    last = None
    for z, rx, ry in shape:
        row = []
        for j in range(24):
            a = j * TAU / 24
            x = rx * math.cos(a)
            y = face(x, z) if math.sin(a) >= 0 else ry * math.sin(a)
            row.append(mesh.vertex((x,y,z), "#FFF5EB", "Head", .94 + .06 * math.sin(a)))
        if last:
            mesh.join(last, row)
        else:
            mesh.faces.append(tuple(reversed(row)))
        last = row
    mesh.faces.append(tuple(last))
    for side in (-1, 1):
        mesh.region = "skin"
        mesh.tube([(side * .119, 0, 1.816, .009,.012), (side * .139, .006, 1.852,.015,.023),
                   (side * .133, .002, 1.890,.010,.015)], "#F8E9DA", "Head", 8)
        eye = [(.026,1.902),(.043,1.911),(.062,1.913),(.083,1.913),(.105,1.914)]
        if form == "woman":
            eye = [(.025,1.900),(.045,1.913),(.066,1.916),(.088,1.917),(.109,1.922)]
        elif form == "child":
            eye = [(.024,1.895),(.043,1.906),(.062,1.909),(.083,1.906),(.102,1.902)]
        points = [(side * x, face(x,z) + .005,z) for x,z in eye]
        mesh.region = "fixed"
        lid = .011 if form == "man" else .015
        mesh.strip(points, [.001,lid*.73,lid,lid*.70,.001], "#F4E6D4", "Head", .001, 2)
        iris = eye[2][1]
        mesh.strip([(side * .064, face(.064,z) + .008, z) for z in (iris-.009,iris,iris+.009)],
                   [.005,.009,.004], "#382F39", "Head", .0006, 2)
        mesh.strip([(side * x, face(x,z) + .010,z + lid * .66) for x,z in eye],
                   [.001,.003,.003,.004,.001], "#352D37", "Head", .0006, 2)
        mesh.region = "hair"
        eyebrow = [(.027,1.930),(.053,1.940),(.084,1.941),(.108,1.935)]
        mesh.strip([(side*x,face(x,z)+.006,z) for x,z in eyebrow],
                   [.001,.004,.005,.001], "#D3C7CD", "Head", .0007, 2)
    mesh.region = "fixed"
    mouth = [(-.026,1.785),(-.010,1.781),(.010,1.781),(.027,1.785)]
    mesh.strip([(x,face(x,z)+.004,z) for x,z in mouth],
               [.001,.003,.003,.001], "#784E4C", "Head", 0, 2)

    mesh.region = "hair"
    last = None
    for t in (0.0, .20, .42, .65, .84, 1.0):
        row = []
        for j in range(24):
            a = j * TAU / 24
            front = max(0, math.sin(a))
            base = (1.775 if form == "woman" else 1.854) + (.198 if form == "woman" else .124) * front ** .64
            z = base * (1 - t) + 2.116 * t
            rx, ry = sample(shape, min(z, 2.070))
            if t == 1.0:
                rx, ry = .021, .027
            x = (rx + .012) * math.cos(a)
            y = (ry + .015) * math.sin(a) - .005
            row.append(mesh.vertex((x, y, z), "#D6CED4", "Head", 1 + .11 * math.sin(a * 6.0 + t * 4)))
        if last:
            mesh.join(last, row)
        last = row
    mesh.faces.append(tuple(last))
    if form == "woman":
        for i in range(4):
            x = -.094 + i * .052
            turn = .026 if i > 1 else -.022
            low = (1.946,1.977,1.993,1.941)[i]
            mesh.tube([(x - turn,.070,2.090,.031,.013), (x,.107,2.056,.036,.019),
                       (x + turn,.129,2.004,.028,.017), (x + turn,.120,low,.003,.004)],
                      "#D4CCD2","Head",8,.17)
    else:
        for i in range(4):
            x = -.085 + i * .049
            low = (1.947,1.979,1.994,1.965)[i]
            mesh.tube([(x + .025,.075,2.079,.028,.014), (x + .014,.118,2.043,.033,.022),
                       (x,.130,1.999,.026,.012), (x-.022,.119,low,.003,.004)],
                      "#D4CCD2","Head",8,.18)
    if form == "woman":
        mesh.tube([(0,-.107,1.863,.044,.036),(0,-.136,1.823,.077,.062),
                   (.007,-.136,1.777,.069,.065),(.011,-.115,1.740,.030,.040)],
                  "#C8BFC7","Head",12,.11)
        for side in (-1, 1):
            mesh.tube([(side*.114,.032,2.011,.025,.020), (side*.137,.052,1.927,.024,.025),
                       (side*.140,.035,1.844,.016,.020), (side*.125,.012,1.805,.004,.008)],
                      "#DDD2D8","Head",8,.10)


def export(form):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.outliner.orphans_purge(do_recursive=True)
    shoulder = {"man": .245, "woman": .195, "child": .174}[form]
    hip = {"man": .124, "woman": .135, "child": .116}[form]
    mesh = CitizenMesh("CitizenCloth")
    jacket(mesh, form, shoulder)
    legs(mesh, form, hip)
    head(mesh, form)
    mesh.points = [(x, y, height(z, form)) for x, y, z in mesh.points]
    rig = build_rig(form, shoulder, hip)
    actor = mesh.create(rig)
    uv = actor.data.uv_layers.new(name="PaintRegions")
    uv.data.foreach_set("uv", [value for loop in actor.data.loops
                               for value in (mesh.colors[loop.vertex_index][3], .5)])
    actor.data.materials[0].use_backface_culling = False
    destination = ROOT / "characters" / "art" / ("townsperson_" + form + ".glb")
    bpy.ops.export_scene.gltf(filepath=str(destination), export_format="GLB",
                             export_animations=False, export_vertex_color="MATERIAL")
    print(form, len(mesh.points), "painted vertices", destination)


if __name__ == "__main__":
    for form in ("man", "woman", "child"):
        export(form)
