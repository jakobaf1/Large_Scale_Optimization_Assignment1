import numpy as np
from itertools import combinations
from scipy.spatial import ConvexHull

# -----------------------------
# DEFINE YOUR MODEL
# a*x + b*y <= c
# -----------------------------

constraints = np.array([
    [-1, -1, -2],     # x + y >= 2
    [1, 1, 5],     # x + y <= 4
    [-1, 1, 0],     # y <= 3
    [1, -1, 1],    # x >= 0  → -x <= 0
    [0, 1, 3],     # y >= 0  → -y <= 0
    [-1, 1, 1],
    [1,0,4],
    [-1/3.0,-1,-7/3.0]
])

# -----------------------------
# STEP 1: Compute all pairwise intersections
# -----------------------------

def intersection(c1, c2):
    A = np.array([[c1[0], c1[1]],
                  [c2[0], c2[1]]])
    b = np.array([c1[2], c2[2]])
    
    if np.linalg.det(A) == 0:
        return None  # Parallel lines
    
    return np.linalg.solve(A, b)

points = []
for c1, c2 in combinations(constraints, 2):
    p = intersection(c1, c2)
    if p is not None:
        points.append(p)

points = np.array(points)

# -----------------------------
# STEP 2: Filter feasible points
# -----------------------------

def is_feasible(point, constraints):
    return all(a*point[0] + b*point[1] <= c + 1e-9 for a, b, c in constraints)

feasible_points = np.array([
    p for p in points if is_feasible(p, constraints)
])

# Remove duplicates
feasible_points = np.unique(feasible_points.round(6), axis=0)

# -----------------------------
# STEP 3: Order vertices (Convex Hull)
# -----------------------------

hull = ConvexHull(feasible_points)
vertices = feasible_points[hull.vertices]

# -----------------------------
# STEP 4: Output for LaTeX
# -----------------------------

feasible_int = []

for x in range(0, 6):
    for y in range(0, 6):
        if all(a*x + b*y <= c + 1e-9 for a, b, c in constraints):
            feasible_int.append((x, y))

print("coordinates {")
for x, y in feasible_int:
    print(f"    ({x},{y})")
print("};")

print("Feasible vertices (ordered):\n")
for v in vertices:
    print(f"({v[0]:.3f}, {v[1]:.3f})")

print("\nLaTeX coordinates:\n")
print("coordinates {")
for v in vertices:
    print(f"    ({v[0]:.3f},{v[1]:.3f})")
print("} -- cycle;")