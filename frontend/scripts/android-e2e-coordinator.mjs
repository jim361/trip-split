import { execFile } from "node:child_process";
import { mkdir, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { promisify } from "node:util";

// Local test rendezvous only. App data still goes through FlutterFire and Rules.
const adb = process.env.ADB ?? "adb";
const guest = process.env.E2E_GUEST_SERIAL ?? "emulator-5556";
if (!/^emulator-\d+$/.test(guest)) throw new Error("An Android emulator is required.");
const run = promisify(execFile);
const output = new URL("../build/android-e2e/", import.meta.url);
await mkdir(output, { recursive: true });
const state = { startedAt: new Date().toISOString() };
async function network(enabled) {
  for (const service of ["wifi", "data"]) {
    await run(adb, ["-s", guest, "shell", "svc", service, enabled ? "enable" : "disable"]);
  }
  state.guestNetworkEnabled = enabled;
}
const server = createServer(async (request, response) => {
  try {
    let body = "";
    for await (const chunk of request) {
      body += chunk;
      if (body.length > 65536) throw new Error("Test message too large.");
    }
    const value = body ? JSON.parse(body) : {};
    let result = state;
    if (request.method === "POST" && request.url === "/register") {
      if (typeof value.uid !== "string" || !value.uid) throw new Error("Missing UID.");
      if (!state.ownerUid) state.ownerUid = value.uid;
      else if (state.ownerUid !== value.uid && !state.guestUid) state.guestUid = value.uid;
      const role =
        state.ownerUid === value.uid ? "owner" : state.guestUid === value.uid ? "guest" : null;
      if (!role) throw new Error("Unexpected third UID; restart must preserve authentication.");
      result = { role, ...state };
    } else if (request.method === "POST" && request.url === "/event") {
      Object.assign(state, value);
      console.log(JSON.stringify(value));
    } else if (request.method === "POST" && request.url === "/guest-network") {
      if (typeof value.enabled !== "boolean") throw new Error("Missing enabled flag.");
      await network(value.enabled);
    } else if (request.method !== "GET" || request.url !== "/state") {
      response.writeHead(404).end();
      return;
    }
    await writeFile(new URL("state.json", output), JSON.stringify(state, null, 2));
    response.writeHead(200, { "Content-Type": "application/json" }).end(JSON.stringify(result));
  } catch (error) {
    console.error(error);
    response.writeHead(500).end(JSON.stringify({ error: String(error) }));
  }
});
server.listen(5877, "127.0.0.1", () => {
  console.log("Android E2E coordinator: http://127.0.0.1:5877 (use adb reverse tcp:5877 tcp:5877)");
});
process.on("SIGINT", async () => {
  await network(true).catch(console.error);
  server.close();
});
