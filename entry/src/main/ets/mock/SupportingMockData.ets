import { EnvironmentModel, HistoryItemModel, SettingsSectionModel } from '../models/ShellModels';

export const DEMO_ENVIRONMENTS: EnvironmentModel[] = [
  {
    id: 'development',
    name: 'Development',
    kind: 'development',
    variables: [
      { id: 'dev-base-url', enabled: true, key: 'baseUrl', value: 'https://dev.api.example.com', description: 'Development API base URL', type: 'text', secret: false },
      { id: 'dev-api-token', enabled: true, key: 'apiToken', value: 'nimbo_demo_token', description: 'Bearer token', type: 'text', secret: true }
    ]
  },
  {
    id: 'staging',
    name: 'Staging',
    kind: 'staging',
    variables: [
      { id: 'staging-base-url', enabled: true, key: 'baseUrl', value: 'https://staging.api.example.com', description: 'Staging API base URL', type: 'text', secret: false }
    ]
  },
  {
    id: 'production',
    name: 'Production',
    kind: 'production',
    variables: [
      { id: 'prod-base-url', enabled: true, key: 'baseUrl', value: 'https://api.example.com', description: 'Production API base URL', type: 'text', secret: false }
    ]
  }
];

export const DEMO_HISTORY: HistoryItemModel[] = [
  { id: 'history-1', group: 'Today', time: '12:31', method: 'GET', url: 'https://jsonplaceholder.typicode.com/users', status: 200, duration: '183 ms' },
  { id: 'history-2', group: 'Today', time: '12:29', method: 'POST', url: 'https://api.example.com/login', status: 200, duration: '91 ms' },
  { id: 'history-3', group: 'Today', time: '12:22', method: 'POST', url: 'https://api.example.com/login', status: 401, duration: '88 ms' },
  { id: 'history-4', group: 'Yesterday', time: '18:04', method: 'PUT', url: 'https://api.example.com/users/7', status: 204, duration: '126 ms' },
  { id: 'history-5', group: 'Previous 7 Days', time: 'Tue', method: 'DELETE', url: 'https://api.example.com/sessions/old', status: 404, duration: '75 ms' },
  { id: 'history-6', group: 'Older', time: 'Aug 21', method: 'GET', url: 'https://api.example.com/health', status: 200, duration: '42 ms' }
];

export const SETTINGS_SECTIONS: SettingsSectionModel[] = [
  { id: 'General', label: 'General', icon: '⌘' },
  { id: 'Appearance', label: 'Appearance', icon: '◐' },
  { id: 'Network', label: 'Network', icon: '⌁' },
  { id: 'Data', label: 'Data', icon: '▤' },
  { id: 'Privacy', label: 'Privacy', icon: '◇' },
  { id: 'About', label: 'About', icon: 'ⓘ' }
];
