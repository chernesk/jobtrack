import type { ButtonHTMLAttributes } from "react";

type Variant = "primary" | "secondary" | "danger";

const VARIANT_STYLES: Record<Variant, string> = {
  primary:
    "bg-slate-900 text-white hover:bg-slate-700 dark:bg-slate-100 dark:text-slate-900 dark:hover:bg-slate-300",
  secondary:
    "bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 ring-1 ring-inset ring-slate-300 dark:ring-slate-600 hover:bg-slate-50 dark:hover:bg-slate-800",
  danger: "bg-red-600 text-white hover:bg-red-500",
};

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
}

// Defaults to type="button" so a Button inside a <form> doesn't submit it
// unless you ask for type="submit".
export default function Button({
  variant = "primary",
  type = "button",
  className = "",
  ...rest
}: ButtonProps) {
  return (
    <button
      type={type}
      className={`rounded px-4 py-2 text-sm font-medium disabled:cursor-not-allowed disabled:opacity-50 ${VARIANT_STYLES[variant]} ${className}`}
      {...rest}
    />
  );
}
