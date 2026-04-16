import numpy as np

# -----------------------------
# DEFINE YOUR MODEL
# a*x + b*y <= c
# -----------------------------

constraints = np.array([
    [-1, -1, -2],
    [1, 1, 5],
    [-1, 1, 0],
    [1, -1, 1],
    [0, 1, 3],
    [-1, 1, 1],
    [1, 0, 4],
    [-1/3.0, -1, -7/3.0]
])

# -----------------------------
# FUNCTION: convert constraint → LaTeX
# -----------------------------

def constraint_to_latex(a, b, c):
    # Case 1: vertical line (b = 0 → x = c/a)
    if abs(b) < 1e-9:
        x_val = c / a
        return f"\\addplot ({{{x_val:.3f}}},{{x}}); % x = {x_val:.3f}"
    
    # Case 2: normal line → y = (c - a x)/b
    m = -a / b
    k = c / b

    # Clean formatting
    def fmt(val):
        if abs(val - round(val)) < 1e-9:
            return str(int(round(val)))
        return f"{val:.3f}"

    m_str = fmt(m)
    k_str = fmt(k)

    if k >= 0:
        return f"\\addplot {{{m_str}*x + {k_str}}};"
    else:
        return f"\\addplot {{{m_str}*x - {fmt(abs(k))}}};"

# -----------------------------
# GENERATE LATEX
# -----------------------------

print("% --- Auto-generated constraint lines ---\n")

for a, b, c in constraints:
    print(constraint_to_latex(a, b, c))