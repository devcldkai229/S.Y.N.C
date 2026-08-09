/** AWS Location Service map configuration (mirrors Flutter AwsMapConfig). */

const region = process.env.NEXT_PUBLIC_AWS_MAP_REGION ?? "ap-southeast-1";
const apiKey = process.env.NEXT_PUBLIC_AWS_MAP_API_KEY ?? "";
const mapName = process.env.NEXT_PUBLIC_AWS_MAP_NAME ?? "sync-map";
const mapStyle = process.env.NEXT_PUBLIC_AWS_MAP_STYLE ?? "Hybrid";

export const AWS_MAP_DEFAULT_LAT = 10.7769;
export const AWS_MAP_DEFAULT_LNG = 106.7009;
export const AWS_MAP_DEFAULT_ZOOM = 12;

export function isAwsMapConfigured(): boolean {
  return apiKey.length > 0;
}

export function getAwsMapStyleDescriptorUrl(): string | null {
  if (!isAwsMapConfigured()) return null;

  if (mapName) {
    return `https://maps.geo.${region}.amazonaws.com/maps/v0/maps/${mapName}/style-descriptor?key=${apiKey}`;
  }

  return `https://maps.geo.${region}.amazonaws.com/v2/styles/${mapStyle}/descriptor?key=${apiKey}`;
}

export const awsMapConfig = {
  region,
  mapName,
  mapStyle,
  isConfigured: isAwsMapConfigured(),
  styleDescriptorUrl: getAwsMapStyleDescriptorUrl(),
} as const;
