// Types for Inertia page props. Each type must match what the Rails controller
// passes to `render inertia:`.

export interface CurrentUser {
  email_address: string;
}

export interface HomeIndexProps {
  user: CurrentUser;
}
