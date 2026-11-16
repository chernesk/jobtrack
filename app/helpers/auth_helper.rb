# Tailwind classes shared by the sign-in and password pages (plain ERB, so no React
# components are available here). Kept in one place so the pages stay consistent.
module AuthHelper
  AUTH_LABEL = "block text-sm font-medium text-slate-700 dark:text-slate-300".freeze
  AUTH_INPUT = "mt-1 block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 shadow-sm " \
               "placeholder:text-slate-400 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/40 " \
               "dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:placeholder:text-slate-500".freeze
  AUTH_BUTTON = "w-full cursor-pointer rounded-lg bg-indigo-600 px-4 py-2.5 font-semibold text-white shadow-sm " \
                "hover:bg-indigo-500 focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 focus-visible:ring-offset-2 " \
                "dark:focus-visible:ring-offset-slate-900".freeze
  AUTH_LINK = "font-medium text-indigo-600 hover:text-indigo-500 dark:text-indigo-400 dark:hover:text-indigo-300".freeze
end
