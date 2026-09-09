import { SettingsSection, SettingsSectionModel } from '../../../models/ShellModels';
import { SETTINGS_SECTIONS } from '../../../mock/SupportingMockData';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { SettingRow } from './SettingRow';

@Component
export struct SettingsPage {
  @State section: SettingsSection = 'General';
  @State restoreTabs: boolean = true;
  @State followRedirects: boolean = true;
  @State sslVerification: boolean = true;
  @State saveHistory: boolean = true;
  @State maskSecrets: boolean = true;
  onSaved: () => void = () => {};
  onReset: () => void = () => {};

  @Builder
  sectionContent() {
    if (this.section === 'General') {
      SettingRow({ title: 'Restore workspace', description: 'Reopen request tabs when Nimbo starts.', toggle: true,
        checked: this.restoreTabs, onToggle: (value: boolean) => { this.restoreTabs = value; this.onSaved(); } })
      SettingRow({ title: 'Language', description: 'Language used by the Nimbo interface.', controlLabel: 'English' })
      SettingRow({ title: 'Keyboard shortcuts', description: 'Use Ctrl+Enter to send, Ctrl+N for a new request, and Ctrl+K to search.', controlLabel: 'View' })
    } else if (this.section === 'Appearance') {
      SettingRow({ title: 'Theme', description: 'Follow the system appearance by default.', controlLabel: 'System' })
      SettingRow({ title: 'Interface density', description: 'Balanced desktop spacing for request-heavy workflows.', controlLabel: 'Comfortable' })
    } else if (this.section === 'Network') {
      SettingRow({ title: 'Follow redirects', description: 'Follow HTTP redirects automatically.', toggle: true,
        checked: this.followRedirects, onToggle: (value: boolean) => { this.followRedirects = value; this.onSaved(); } })
      SettingRow({ title: 'SSL certificate verification', description: 'Verify server certificates before connecting.', toggle: true,
        checked: this.sslVerification, onToggle: (value: boolean) => { this.sslVerification = value; this.onSaved(); } })
      SettingRow({ title: 'Request timeout', description: 'Maximum wait time for a response.', controlLabel: '30 seconds' })
    } else if (this.section === 'Data') {
      SettingRow({ title: 'Save request history', description: 'Keep a local record of sent requests.', toggle: true,
        checked: this.saveHistory, onToggle: (value: boolean) => { this.saveHistory = value; this.onSaved(); } })
      SettingRow({ title: 'History retention', description: 'Remove local history after the selected period.', controlLabel: '30 days' })
      SettingRow({ title: 'Reset Nimbo', description: 'Remove local collections, environments, history, and settings.',
        controlLabel: 'Reset App', dangerous: true, onPress: this.onReset })
    } else if (this.section === 'Privacy') {
      SettingRow({ title: 'Mask secret values', description: 'Hide secret environment values in editors and previews.', toggle: true,
        checked: this.maskSecrets, onToggle: (value: boolean) => { this.maskSecrets = value; this.onSaved(); } })
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
