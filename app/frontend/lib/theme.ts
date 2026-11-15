export type Theme = "light" | "dark";

const STORAGE_KEY = "theme";

// Storage can throw (private windows, blocked site data), and the app must still
// work, so every access is wrapped.
export function storedTheme(): Theme | null {
  try {
    const value = localStorage.getItem(STORAGE_KEY);
    return value === "light" || value === "dark" ? value : null;
  } catch {
    return null;
  }
}

// The theme currently on screen. The inline script in app/views/layouts/_theme.html.erb
// sets the `dark` class on <html> before first paint; this reads it back.
export function currentTheme(): Theme {
  return document.documentElement.classList.contains("dark") ? "dark" : "light";
}

export function applyTheme(theme: Theme): void {
  document.documentElement.classList.toggle("dark", theme === "dark");
  try {
    localStorage.setItem(STORAGE_KEY, theme);
  } catch {
    // Not persisted, but the choice still applies for this visit.
  }
}
