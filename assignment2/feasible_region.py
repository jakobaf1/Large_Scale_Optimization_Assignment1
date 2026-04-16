import numpy as np
import matplotlib.pyplot as plt
from scipy.spatial import HalfspaceIntersection, ConvexHull

# -----------------------------
# DEFINE YOUR MODEL HERE
# Each constraint: a*x + b*y <= c
# Format: [a, b, c]
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
# CONVERT to Halfspace format:
# a*x + b*y + d <= 0
# -----------------------------

halfspaces = np.array([[a, b, -c] for a, b, c in constraints])

# -----------------------------
# FEASIBLE POINT (must satisfy all constraints)
# Pick something clearly inside
# -----------------------------

feasible_point = np.array([4, 1])

# -----------------------------
# COMPUTE INTERSECTION
# -----------------------------

hs = HalfspaceIntersection(halfspaces, feasible_point)

# Extract intersection points
points = hs.intersections

# Compute convex hull (orders vertices correctly)
hull = ConvexHull(points)
polygon = points[hull.vertices]

# -----------------------------
# PLOT
# -----------------------------

plt.figure(figsize=(6, 6))

# Plot feasible region
plt.fill(polygon[:, 0], polygon[:, 1], alpha=0.3)

# Plot boundary
plt.plot(polygon[:, 0], polygon[:, 1], 'k-')

# Plot vertices
plt.plot(points[:, 0], points[:, 1], 'o')

# Axis formatting
plt.xlim(0, 6)
plt.ylim(0, 6)
plt.xlabel('x')
plt.ylabel('y')
plt.title('Feasible Region')
plt.grid(True)

plt.show()