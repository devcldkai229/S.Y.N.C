import Client from "./client";

/** Next 16 static export rejects empty generateStaticParams — emit one shell path. */
export function generateStaticParams() {
  return [{ id: "_" }];
}

export default function Page() {
  return <Client />;
}
