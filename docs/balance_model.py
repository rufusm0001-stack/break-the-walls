PUNCH = 1 / 0.35   # punches per second (Config.Fists.cooldown)
EFF = 0.45          # measured: real sweeping hits ~45% of the ideal 3*D/H cubes per punch
WALK = 16
zones = {1: dict(v=1, H=1, d=30, depth=5), 2: dict(v=3, H=1.5, d=75, depth=6), 3: dict(v=8, H=2, d=85, depth=7)}
kits = [
    (1, "Bare fists + Basic (50)", 1, 50),
    (1, "Bronze + Turbo (75)", 1.5, 75),
    (1, "Iron + Cyclone (100)", 2, 100),
    (2, "Bronze + Turbo (75)", 1.5, 75),
    (2, "Iron + Cyclone (100)", 2, 100),
    (2, "Gold + Mega (150)", 3, 150),
    (3, "Iron + Cyclone (100)", 2, 100),
    (3, "Gold + Mega (150)", 3, 150),
    (3, "Diamond + Titan (225)", 4.5, 225),
    (3, "Energy + Vortex (350)", 6, 350),
]
print("| Zone | Kit | Cubes/s | Trip (s) | $/trip | $/min | Break-through (punching only) |")
print("|---|---|---|---|---|---|---|")
for z, name, D, S in kits:
    zz = zones[z]
    r = PUNCH * min(5, 3 * D / zz["H"]) * EFF
    trip = S / r + 2 * zz["d"] / WALK + 1 + S * 0.015
    pay = S * zz["v"]
    perMin = pay / trip * 60
    need = 4 * 6 * zz["depth"] * 1.7
    print(f"| {z} | {name} | {r:.1f} | {trip:.0f} | ${pay:,} | ${perMin:,.0f} | {need/r:.0f} s ({need:.0f} cubes) |")
