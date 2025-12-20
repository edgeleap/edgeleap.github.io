# edgeleap.github.io
landingpage for edgeleap

The landing page features a "darkmode devtools" aesthetic, a vertical stack layout, and a responsive design.

### Key Design Choices[1]
1.  **Devtools Vibe**: Used a dark theme (`#0d1117`) similar to GitHub's dark mode or VS Code. The font stack is purely monospace (`SFMono`, `Consolas`, etc.) to mimic a coding environment.
2.  **Vertical Stack**: The layout uses a single column flex container (`align-items: center`) to stack the title, hero, instructions, and features vertically.
3.  **Hero Section**:
    *   **Terminal**: Styled with macOS-like window controls (red/yellow/green dots) and syntax highlighting colors for the git commands.
    *   **Popover**: Positioned absolutely (in desktop view) to "float" over the terminal, simulating the actual behavior of the app popping up a window. It has a slight float animation to draw attention.
4.  **Feature Grid**: Simple, border-based cards that look like code blocks or data panels.
5.  **Responsiveness**: On mobile screens, the popover stacks below the terminal naturally to ensure readability.
