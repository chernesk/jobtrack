import js from "@eslint/js";
import prettier from "eslint-config-prettier";
import reactHooks from "eslint-plugin-react-hooks";
import globals from "globals";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["node_modules", "public", "vendor", "tmp", "coverage"] },
  js.configs.recommended,
  reactHooks.configs.flat.recommended,
  {
    // App code: type-aware rules (e.g. no-floating-promises) use the tsconfig,
    // so they can see the real types, not just the syntax.
    files: ["app/frontend/**/*.{ts,tsx}"],
    extends: [...tseslint.configs.recommendedTypeChecked],
    languageOptions: {
      globals: globals.browser,
      parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
    },
    rules: {
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/ban-ts-comment": "error",
      "@typescript-eslint/no-non-null-assertion": "error",
      "@typescript-eslint/consistent-type-imports": "error",
    },
  },
  {
    // Config files (eslint.config.js etc.) run in Node, not the browser.
    files: ["*.{js,ts}"],
    languageOptions: { globals: globals.node },
  },
  {
    // Test files mock modules and use Testing Library's async helpers; the
    // unbound-method rule flags `expect(router.delete)` style assertions.
    files: ["app/frontend/**/*.test.{ts,tsx}"],
    rules: { "@typescript-eslint/unbound-method": "off" },
  },
  // Must come last: turns off ESLint rules that would fight Prettier.
  prettier,
);
