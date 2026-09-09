import { SettingsSection, SettingsSectionModel } from '../../../models/ShellModels';
import { AppPreferencesModel } from '../../../models/PersistenceModels';
import { createDefaultPreferences } from '../../../state/AppDefaults';
import { SETTINGS_SECTIONS } from '../../../mock/SupportingMockData';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { SettingRow } from './SettingRow';

@Component
export struct SettingsPage {
  @State section: SettingsSection = 'General';
  @Prop preferences: AppPreferencesModel = createDefaultPreferences();
  onChange: (preferences: AppPreferencesModel) => void = () => {};
  onReset: () => void = () => {};

  private emit(restoreWorkspace: boolean, language: 'en' | 'zh', followRedirects: boolean,
    sslVerification: boolean, defaultTimeoutMs: number, saveHistory: boolean,
    historyRetentionDays: number, maskSecrets: boolean): void {
    this.onChange({ restoreWorkspace, language, followRedirects, sslVerification, defaultTimeoutMs,
      saveHistory, historyRetentionDays, maskSecrets });
  }

  private timeoutLabel(): string {
    return `${this.preferences.defaultTimeoutMs / 1000} seconds`;
  }

  private nextTimeout(): number {
    if (this.preferences.defaultTimeoutMs === 15000) return 30000;
    if (this.preferences.defaultTimeoutMs === 30000) return 60000;
    if (this.preferences.defaultTimeoutMs === 60000) return 120000;
    return 15000;
  }

  private nextRetention(): number {
    if (this.preferences.historyRetentionDays === 7) return 30;
    if (this.preferences.historyRetentionDays === 30) return 90;
    return 7;
  }

  @Builder
  sectionContent() {
    if (this.section === 'General') {
      SettingRow({ title: 'Restore workspace', description: 'Reopen request tabs when Nimbo starts.', toggle: true,
        checked: this.preferences.restoreWorkspace, onToggle: (value: boolean) => this.emit(value,
          this.preferences.language, this.preferences.followRedirects, this.preferences.sslVerification,
          this.preferences.defaultTimeoutMs, this.preferences.saveHistory,
          this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      SettingRow({ title: 'Language', description: 'Language used by the Nimbo interface.',
        controlLabel: this.preferences.language === 'zh' ? '简体中文' : 'English' })
      SettingRow({ title: 'Keyboard shortcuts', description: 'Use Ctrl+Enter to send, Ctrl+N for a new request, and Ctrl+K to search.', controlLabel: 'View' })
    } else if (this.section === 'Appearance') {
      SettingRow({ title: 'Theme', description: 'Follow the system appearance by default.', controlLabel: 'System' })
      SettingRow({ title: 'Interface density', description: 'Balanced desktop spacing for request-heavy workflows.', controlLabel: 'Comfortable' })
    } else if (this.section === 'Network') {
      SettingRow({ title: 'Follow redirects', description: 'Follow HTTP redirects automatically.', toggle: true,
        checked: this.preferences.followRedirects, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, value,
          this.preferences.sslVerification, this.preferences.defaultTimeoutMs,
          this.preferences.saveHistory, this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      SettingRow({ title: 'SSL certificate verification', description: 'Verify server certificates before connecting.', toggle: true,
        checked: this.preferences.sslVerification, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, this.preferences.followRedirects,
          value, this.preferences.defaultTimeoutMs, this.preferences.saveHistory,
          this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      if (!this.preferences.sslVerification) {
        Text('Warning: disabling SSL verification weakens connection security for new requests.')
          .fontSize(12)
          .fontColor(ColorTokens.httpDelete)
          .width('100%')
          .padding(SpacingTokens.x3)
          .backgroundColor(ColorTokens.statusDangerBackground)
          .borderRadius(RadiusTokens.small)
      }
      SettingRow({ title: 'Request timeout', description: 'Default for newly created requests.',
        controlLabel: this.timeoutLabel(), onPress: () => this.emit(this.preferences.restoreWorkspace,
          this.preferences.language, this.preferences.followRedirects, this.preferences.sslVerification,
          this.nextTimeout(), this.preferences.saveHistory, this.preferences.historyRetentionDays,
          this.preferences.maskSecrets) })
    } else if (this.section === 'Data') {
      SettingRow({ title: 'Save request history', description: 'Keep a local record of sent requests.', toggle: true,
        checked: this.preferences.saveHistory, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, this.preferences.followRedirects,
          this.preferences.sslVerification, this.preferences.defaultTimeoutMs, value,
          this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      SettingRow({ title: 'History retention', description: 'Remove local history after the selected period.',
        controlLabel: `${this.preferences.historyRetentionDays} days`,
        onPress: () => this.emit(this.preferences.restoreWorkspace, this.preferences.language,
          this.preferences.followRedirects, this.preferences.sslVerification,
          this.preferences.defaultTimeoutMs, this.preferences.saveHistory, this.nextRetention(),
          this.preferences.maskSecrets) })
      SettingRow({ title: 'Reset Nimbo', description: 'Remove local collections, environments, history, and settings.',
        controlLabel: 'Reset App', dangerous: true, onPress: this.onReset })
    } else if (this.section === 'Privacy') {
      SettingRow({ title: 'Mask secret values', description: 'Hide secret environment values in editors and previews.', toggle: true,
        checked: this.preferences.maskSecrets, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, this.preferences.followRedirects,
          this.preferences.sslVerification, this.preferences.defaultTimeoutMs,
          this.preferences.saveHistory, this.preferences.historyRetentionDays, value) })
      SettingRow({ title: 'Export secrets', description: 'Exporting secrets requires explicit confirmation.', controlLabel: 'Export…' })
    } else {
      SettingRow({ title: 'Nimbo', description: 'A fast, native API workspace for HarmonyOS PC.', controlLabel: 'Version 0.1.0' })
      SettingRow({ title: 'Application identity', description: 'Bundle com.nimbo.app · App ID 6917615930484878194', controlLabel: 'Local build' })
    }
  }

  build() {
    Row() {
      Column() {
        Text('Settings')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
          .width('100%')
          .height(48)
          .padding({ left: SpacingTokens.x3 })
        ForEach(SETTINGS_SECTIONS, (item: SettingsSectionModel) => {
          Row({ space: SpacingTokens.x3 }) {
            Text(item.icon).width(20).fontSize(15).textAlign(TextAlign.Center)
              .fontColor(item.id === this.section ? ColorTokens.brand500 : ColorTokens.textTertiary)
            Text(item.label).fontSize(13)
              .fontColor(item.id === this.section ? ColorTokens.brand600 : ColorTokens.textSecondary)
          }
          .width('100%')
          .height(40)
          .padding({ left: SpacingTokens.x3 })
          .backgroundColor(item.id === this.section ? ColorTokens.bgSurfaceActive : ColorTokens.bgSidebar)
          .borderRadius(RadiusTokens.medium)
          .onClick(() => { this.section = item.id; })
        }, (item: SettingsSectionModel) => item.id)
        Blank()
      }
      .width(220)
      .height('100%')
      .padding(SpacingTokens.x2)
      .backgroundColor(ColorTokens.bgSidebar)
      .border({ width: { right: 1 }, color: ColorTokens.borderSubtle })

      Scroll() {
        Column() {
          Text(this.section)
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
            .width('100%')
          Text('Configure Nimbo for your local API workflow.')
            .fontSize(12)
            .fontColor(ColorTokens.textTertiary)
            .width('100%')
            .margin({ top: SpacingTokens.x1, bottom: SpacingTokens.x5 })
          this.sectionContent()
        }
        .width('100%')
        .padding({ left: 40, right: 40, top: 30, bottom: 40 })
      }
      .layoutWeight(1)
      .height('100%')
      .backgroundColor(ColorTokens.bgWorkspace)
    }
    .width('100%')
    .height('100%')
  }
}
