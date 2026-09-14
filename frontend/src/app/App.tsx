import { AppRouter } from "./routes";
import "../shared/styles/global.css";
import { AuthProvider, PlatformServicesProvider } from "./providers";

export function App() {
  return (
    <PlatformServicesProvider>
      <AuthProvider>
        <AppRouter />
      </AuthProvider>
    </PlatformServicesProvider>
  );
}

export default App;
