import { useId, type ReactNode } from "react";

// What the field hands to the control so label, input and error stay wired up
// for screen readers.
interface ControlProps {
  id: string;
  "aria-invalid": boolean;
  "aria-describedby": string | undefined;
  className: string;
}

interface FieldProps {
  label: string;
  error?: string | undefined;
  // Render prop: the caller renders whichever control it needs (input,
  // textarea, select) and spreads the props it receives onto it.
  children: (control: ControlProps) => ReactNode;
}

const BASE_CONTROL =
  "mt-1 block w-full rounded border bg-white px-3 py-2 text-sm text-slate-900 dark:bg-slate-800 dark:text-slate-100";

export default function Field({ label, error, children }: FieldProps) {
  const id = useId();
  const errorId = `${id}-error`;
  const className = `${BASE_CONTROL} ${error ? "border-red-500 dark:border-red-400" : "border-slate-300 dark:border-slate-600"}`;

  return (
    <div>
      <label htmlFor={id} className="block text-sm font-medium text-slate-700 dark:text-slate-300">
        {label}
      </label>
      {children({
        id,
        "aria-invalid": Boolean(error),
        "aria-describedby": error ? errorId : undefined,
        className,
      })}
      {error && (
        <p id={errorId} role="alert" className="mt-1 text-sm text-red-600 dark:text-red-400">
          {error}
        </p>
      )}
    </div>
  );
}
