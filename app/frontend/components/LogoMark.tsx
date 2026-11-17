interface LogoMarkProps {
  className?: string;
}

// The JobTrack mark: a briefcase on an indigo tile. Decorative (the name sits next to
// it), so it is hidden from screen readers. Keep the shapes in step with public/icon.svg
// and app/views/layouts/auth.html.erb.
export default function LogoMark({ className = "h-8 w-8" }: LogoMarkProps) {
  return (
    <span
      aria-hidden="true"
      className={`inline-flex shrink-0 items-center justify-center rounded-lg bg-indigo-600 text-white ${className}`}
    >
      <svg
        viewBox="0 0 24 24"
        className="h-[60%] w-[60%]"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <rect x="3" y="7" width="18" height="13" rx="2" />
        <path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
        <path d="M3 13h18" />
      </svg>
    </span>
  );
}
