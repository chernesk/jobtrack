import { useState } from "react";

import { applyTheme, currentTheme, type Theme } from "../lib/theme";
import Button from "./Button";

// The initial value is read from <html>, where the pre-paint script already put
// the right class (stored choice, else the OS setting). So React never has to
// guess, and there is no effect and no flash.
export default function ThemeToggle() {
  const [theme, setTheme] = useState<Theme>(currentTheme);
  const next: Theme = theme === "dark" ? "light" : "dark";

  function toggle() {
    applyTheme(next);
    setTheme(next);
  }

  return (
    <Button variant="secondary" onClick={toggle}>
      {next === "dark" ? "Dark mode" : "Light mode"}
    </Button>
  );
}
