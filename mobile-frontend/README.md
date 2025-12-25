# FinFlow Mobile Frontend

React Native mobile application for the FinFlow financial operations platform.

## Features

- ✅ User authentication (login, register, password reset)
- ✅ Dashboard with financial overview
- ✅ Payment management and processing
- ✅ Financial reports (Balance Sheet, Income Statement, Cash Flow)
- ✅ Analytics and metrics visualization
- ✅ Credit score and loan management
- ✅ User profile management
- ✅ Cross-platform support (iOS & Android)

## Tech Stack

- **Framework**: React Native with Expo
- **Language**: TypeScript
- **State Management**: Redux Toolkit
- **Navigation**: React Navigation (Stack, Tabs, Drawer)
- **UI Components**: React Native Paper
- **API Client**: Axios
- **Testing**: Jest + React Native Testing Library

## Prerequisites

- Node.js >= 16
- npm or yarn
- Expo CLI: `npm install -g expo-cli`
- For iOS: Xcode and iOS Simulator
- For Android: Android Studio and Android Emulator

## Installation

1. Install dependencies:

```bash
npm install
```

2. Create environment configuration:

```bash
cp .env.example .env
```

3. Update `.env` with your backend URL:

```env
API_URL=http://localhost:8080
```

**Note**: For Android emulator, use `http://10.0.2.2:8080` instead of `localhost`.

## Running the App

### Development Mode

```bash
# Start Expo development server
npm start

# Or directly start on a specific platform
npm run android  # Android
npm run ios      # iOS
npm run web      # Web browser
```

### Using Expo Go

1. Install Expo Go app on your phone
2. Run `npm start`
3. Scan the QR code with Expo Go (Android) or Camera (iOS)

### Building for Production

```bash
# Android APK
expo build:android

# iOS IPA
expo build:ios

# Or use EAS Build (recommended)
eas build --platform android
eas build --platform ios
```

## Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Generate coverage report
npm run test:coverage
```

## Project Structure

```
mobile-frontend/
├── assets/                 # Images, fonts, and other static assets
├── src/
│   ├── __tests__/         # Test files
│   │   ├── components/    # Component tests
│   │   ├── screens/       # Screen tests
│   │   └── integration/   # Integration tests
│   ├── components/        # Reusable components
│   │   ├── common/        # Common UI components
│   │   ├── dashboard/     # Dashboard-specific components
│   │   ├── navigation/    # Navigation components
│   │   └── payments/      # Payment-specific components
│   ├── hooks/             # Custom React hooks
│   ├── navigation/        # Navigation configuration
│   ├── screens/           # Screen components
│   │   ├── auth/          # Authentication screens
│   │   ├── dashboard/     # Dashboard screen
│   │   ├── payments/      # Payment screens
│   │   ├── accounting/    # Accounting screens
│   │   ├── analytics/     # Analytics screens
│   │   ├── credit/        # Credit and loan screens
│   │   ├── profile/       # Profile screen
│   │   └── settings/      # Settings screen
│   ├── services/          # API services
│   ├── store/             # Redux store and slices
│   └── types/             # TypeScript type definitions
├── App.tsx                # Root component
├── app.json               # Expo configuration
├── babel.config.js        # Babel configuration
├── metro.config.js        # Metro bundler configuration
├── tsconfig.json          # TypeScript configuration
└── package.json           # Dependencies and scripts
```

## Key Components

### Screens

- **AuthScreens**: Login, Register, Forgot Password
- **DashboardScreen**: Financial overview with key metrics
- **PaymentsScreen**: List and manage payments
- **AccountingScreens**: Balance Sheet, Income Statement, Cash Flow
- **AnalyticsScreen**: Visual analytics and reports
- **CreditScreens**: Credit score, loan management
- **ProfileScreen**: User profile management
- **SettingsScreen**: App settings and preferences

### Redux Store

- **authSlice**: Authentication state and actions
- **paymentsSlice**: Payment data and operations
- **accountingSlice**: Financial reports and journal entries
- **analyticsSlice**: Dashboard metrics and analytics
- **creditSlice**: Credit score and loan data

### API Services

All API calls are centralized in `src/services/api.ts`:

- `authApi`: Authentication endpoints
- `paymentsApi`: Payment operations
- `accountingApi`: Financial reports
- `analyticsApi`: Analytics and metrics
- `creditApi`: Credit and loan management

## Backend Integration

The mobile app communicates with the FinFlow backend services via the API Gateway.

### Starting the Backend

1. Navigate to the backend directory:

```bash
cd ../backend
```

2. Start services with Docker Compose:

```bash
docker-compose up
```

3. Verify services are running:

```bash
docker ps
```

### API Configuration

The API base URL is configured in `src/services/api.ts`. Update the `API_URL` constant for different environments:

- **Development**: `http://localhost:8080` (iOS) or `http://10.0.2.2:8080` (Android)
- **Production**: Your deployed backend URL

## Troubleshooting

### Common Issues

#### 1. Cannot connect to backend

**Problem**: App shows network errors when trying to login or fetch data.

**Solutions**:

- Verify backend is running: `docker ps`
- For Android emulator: Use `http://10.0.2.2:8080` instead of `localhost`
- For physical device: Use your computer's IP address (e.g., `http://192.168.1.x:8080`)
- Check firewall settings

#### 2. Metro bundler issues

**Problem**: App won't start or shows bundling errors.

**Solutions**:

```bash
# Clear cache and restart
npm start -- --clear

# Reset Metro bundler cache
npm start -- --reset-cache

# Clear watchman (if installed)
watchman watch-del-all
```

#### 3. Module resolution errors

**Problem**: Import errors or module not found.

**Solutions**:

```bash
# Reinstall dependencies
rm -rf node_modules
npm install

# Clear Expo cache
expo start -c
```

#### 4. Test failures

**Problem**: Tests fail to run or show errors.

**Solutions**:

```bash
# Clear Jest cache
jest --clearCache

# Update snapshots if needed
npm test -- -u
```

### Platform-Specific Issues

#### iOS

- Ensure Xcode is installed and updated
- Run `npx pod-install` if using bare React Native
- Check iOS Simulator is running

#### Android

- Ensure Android Studio is installed
- Verify Android SDK is properly configured
- Start Android Emulator before running app
- Check `ANDROID_HOME` environment variable

## Development Guidelines

### Code Style

- Use TypeScript for type safety
- Follow React hooks best practices
- Use functional components
- Implement proper error handling
- Add loading states for async operations

### Component Guidelines

- Keep components small and focused
- Use custom hooks for reusable logic
- Implement proper prop typing
- Add error boundaries where appropriate

### State Management

- Use Redux Toolkit for global state
- Use local state for UI-only state
- Implement async thunks for API calls
- Handle loading and error states

### Testing

- Write tests for all new components
- Test user interactions and flows
- Mock API calls in unit tests
- Maintain high test coverage (>80%)

## Contributing

1. Create a feature branch
2. Make changes with tests
3. Ensure all tests pass
4. Submit a pull request

## License

MIT License - see LICENSE file for details
