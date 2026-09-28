import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

type HelpSection = 'start' | 'collections' | 'import' | 'requests' | 'variables' | 'scripts' |
  'automation' | 'runner' | 'realtime' | 'shortcuts' | 'troubleshooting';

interface HelpSectionModel {
  id: HelpSection;
  label: ResourceStr;
}

@Component
export struct HelpPage {
  @Prop phone: boolean = false;
  @State section: HelpSection = 'start';

  private sections: HelpSectionModel[] = [
    { id: 'start', label: $r('app.string.help_section_start') },
    { id: 'collections', label: $r('app.string.help_section_collections') },
    { id: 'import', label: $r('app.string.help_section_import') },
    { id: 'requests', label: $r('app.string.help_section_requests') },
    { id: 'variables', label: $r('app.string.help_section_variables') },
    { id: 'scripts', label: $r('app.string.help_section_scripts') },
    { id: 'automation', label: $r('app.string.help_section_automation') },
    { id: 'runner', label: $r('app.string.help_section_runner') },
    { id: 'realtime', label: $r('app.string.help_section_realtime') },
    { id: 'shortcuts', label: $r('app.string.help_section_shortcuts') },
    { id: 'troubleshooting', label: $r('app.string.help_section_troubleshooting') }
  ];

  private sectionTitle(): ResourceStr {
    const item = this.sections.find((candidate: HelpSectionModel) => candidate.id === this.section);
    return item ? item.label : $r('app.string.help_section_start');
  }

  @Builder
  private guideCard(title: ResourceStr, description: ResourceStr) {
    Column({ space: SpacingTokens.x2 }) {
      Text(title).width('100%').fontSize(14).fontWeight(FontWeight.Medium)
        .fontColor(ColorTokens.textPrimary)
      Text(description).width('100%').fontSize(12).lineHeight(20)
        .fontColor(ColorTokens.textSecondary)
    }
    .width('100%')
    .padding(SpacingTokens.x4)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.medium)
  }

  @Builder
  private codeBlock(value: string) {
    Text(value)
      .width('100%')
      .padding(SpacingTokens.x3)
      .fontSize(12)
      .fontFamily('monospace')
      .fontColor(ColorTokens.brand600)
      .backgroundColor(ColorTokens.bgApp)
      .border({ width: 1, color: ColorTokens.borderSubtle })
      .borderRadius(RadiusTokens.small)
      .copyOption(CopyOptions.LocalDevice)
  }

  @Builder
  private sectionContent() {
    if (this.section === 'start') {
      this.guideCard($r('app.string.help_start_create_title'), $r('app.string.help_start_create_body'))
      this.guideCard($r('app.string.help_start_send_title'), $r('app.string.help_start_send_body'))
      this.guideCard($r('app.string.help_start_save_title'), $r('app.string.help_start_save_body'))
      this.guideCard($r('app.string.help_start_local_title'), $r('app.string.help_start_local_body'))
    } else if (this.section === 'collections') {
      this.guideCard($r('app.string.help_collection_structure_title'),
        $r('app.string.help_collection_structure_body'))
      this.guideCard($r('app.string.help_collection_manage_title'), $r('app.string.help_collection_manage_body'))
      this.guideCard($r('app.string.help_collection_save_title'), $r('app.string.help_collection_save_body'))
      this.guideCard($r('app.string.help_collection_environment_title'),
        $r('app.string.help_collection_environment_body'))
    } else if (this.section === 'import') {
      this.guideCard($r('app.string.help_import_curl_title'), $r('app.string.help_import_curl_body'))
      this.guideCard($r('app.string.help_import_api_title'), $r('app.string.help_import_api_body'))
      this.guideCard($r('app.string.help_import_mapping_title'), $r('app.string.help_import_mapping_body'))
      this.guideCard($r('app.string.help_import_failure_title'), $r('app.string.help_import_failure_body'))
    } else if (this.section === 'requests') {
      this.guideCard($r('app.string.help_request_compose_title'), $r('app.string.help_request_compose_body'))
      this.guideCard($r('app.string.help_request_auth_title'), $r('app.string.help_request_auth_body'))
      this.guideCard($r('app.string.help_request_body_title'), $r('app.string.help_request_body_body'))
      this.guideCard($r('app.string.help_request_response_title'), $r('app.string.help_request_response_body'))
      this.guideCard($r('app.string.help_request_error_title'), $r('app.string.help_request_error_body'))
    } else if (this.section === 'variables') {
      this.guideCard($r('app.string.help_variable_scope_title'), $r('app.string.help_variable_scope_body'))
      this.codeBlock('Runner > Nearest Folder > Parent Folder > Collection > Environment')
      this.guideCard($r('app.string.help_variable_use_title'), $r('app.string.help_variable_use_body'))
      this.codeBlock('{{BASE_URL}}/users/{{USER_ID}}')
      this.guideCard($r('app.string.help_variable_diagnose_title'), $r('app.string.help_variable_diagnose_body'))
      this.guideCard($r('app.string.help_variable_secret_title'), $r('app.string.help_variable_secret_body'))
      this.guideCard($r('app.string.help_variable_rules_title'), $r('app.string.help_variable_rules_body'))
    } else if (this.section === 'scripts') {
      this.guideCard($r('app.string.help_script_syntax_title'), $r('app.string.help_script_syntax_body'))
      this.codeBlock("const payload = JSON.parse(nimbo.request.body);\nif (payload.name) {\n  payload.name = payload.name.trim();\n}\nnimbo.request.body = JSON.stringify(payload);")
      this.guideCard($r('app.string.help_script_pre_title'), $r('app.string.help_script_pre_body'))
      this.codeBlock("nimbo.request.method = 'POST';\nnimbo.request.url = nimbo.environment.get('BASE_URL') + '/users';\nnimbo.request.bodyType = 'json';\nnimbo.request.headers.set('Content-Type', 'application/json');\nnimbo.request.headers.remove('X-Debug');")
      this.guideCard($r('app.string.help_script_request_api_title'),
        $r('app.string.help_script_request_api_body'))
      this.guideCard($r('app.string.help_script_post_title'), $r('app.string.help_script_post_body'))
      this.codeBlock("const payload = JSON.parse(nimbo.response.body);\nif (nimbo.response.statusCode >= 200 && nimbo.response.statusCode < 300) {\n  nimbo.environment.set('responseId', payload.id);\n}\nconsole.log('request-id', nimbo.response.headers.get('x-request-id'));")
      this.guideCard($r('app.string.help_script_response_api_title'),
        $r('app.string.help_script_response_api_body'))
      this.guideCard($r('app.string.help_script_environment_title'),
        $r('app.string.help_script_environment_body'))
      this.codeBlock("const token = nimbo.environment.get('ACCESS_TOKEN');\nif (!token) throw new Error('ACCESS_TOKEN is required');\nnimbo.request.headers.set('Authorization', 'Bearer ' + token);")
      this.guideCard($r('app.string.help_script_console_title'), $r('app.string.help_script_console_body'))
      this.codeBlock("console.log('status', nimbo.response.statusCode);\nconsole.info('type', nimbo.response.contentType);\nconsole.warn('duration', nimbo.response.duration);\nconsole.error('debug message');")
      this.guideCard($r('app.string.help_script_completion_title'),
        $r('app.string.help_script_completion_body'))
      this.guideCard($r('app.string.help_script_order_title'), $r('app.string.help_script_order_body'))
      this.guideCard($r('app.string.help_script_safety_title'), $r('app.string.help_script_safety_body'))
    } else if (this.section === 'automation') {
      this.guideCard($r('app.string.help_automation_extract_title'), $r('app.string.help_automation_extract_body'))
      this.guideCard($r('app.string.help_automation_test_title'), $r('app.string.help_automation_test_body'))
      this.guideCard($r('app.string.help_automation_order_title'), $r('app.string.help_automation_order_body'))
    } else if (this.section === 'runner') {
      this.guideCard($r('app.string.help_automation_runner_title'), $r('app.string.help_automation_runner_body'))
      this.guideCard($r('app.string.help_runner_start_title'), $r('app.string.help_runner_start_body'))
      this.guideCard($r('app.string.help_runner_data_title'), $r('app.string.help_runner_data_body'))
      this.codeBlock('CSV: key,name\nvalue,Alice\nJSON: [{ "key": "value", "name": "Alice" }]')
      this.guideCard($r('app.string.help_runner_report_title'), $r('app.string.help_runner_report_body'))
      this.guideCard($r('app.string.help_runner_limits_title'), $r('app.string.help_runner_limits_body'))
    } else if (this.section === 'realtime') {
      this.guideCard($r('app.string.help_realtime_ws_title'), $r('app.string.help_realtime_ws_body'))
      this.guideCard($r('app.string.help_realtime_sse_title'), $r('app.string.help_realtime_sse_body'))
      this.guideCard($r('app.string.help_realtime_history_title'), $r('app.string.help_realtime_history_body'))
    } else if (this.section === 'shortcuts') {
      this.guideCard($r('app.string.help_shortcut_search_title'), $r('app.string.help_shortcut_search_body'))
      this.guideCard($r('app.string.help_shortcut_send_title'), $r('app.string.help_shortcut_send_body'))
      this.guideCard($r('app.string.help_shortcut_save_title'), $r('app.string.help_shortcut_save_body'))
      this.guideCard($r('app.string.help_shortcut_editor_title'), $r('app.string.help_shortcut_editor_body'))
    } else {
      this.guideCard($r('app.string.help_trouble_variable_title'), $r('app.string.help_trouble_variable_body'))
      this.guideCard($r('app.string.help_trouble_network_title'), $r('app.string.help_trouble_network_body'))
      this.guideCard($r('app.string.help_trouble_import_title'), $r('app.string.help_trouble_import_body'))
      this.guideCard($r('app.string.help_trouble_restore_title'), $r('app.string.help_trouble_restore_body'))
    }
  }

  @Builder
  private sectionNavigation(horizontal: boolean) {
    ForEach(this.sections, (item: HelpSectionModel) => {
      Row() {
        Text(item.label).fontSize(12).fontWeight(item.id === this.section ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(item.id === this.section ? ColorTokens.brand600 : ColorTokens.textSecondary)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .height(40)
      .width(horizontal ? 140 : '100%')
      .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
      .backgroundColor(item.id === this.section ? ColorTokens.bgSurfaceActive : Color.Transparent)
      .borderRadius(RadiusTokens.medium)
      .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
      .onClick(() => {
        this.getUIContext().animateTo({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }, () => {
          this.section = item.id;
        });
      })
    }, (item: HelpSectionModel) => item.id)
  }

  @Builder
  private contentArea() {
    Scroll() {
      Column({ space: SpacingTokens.x3 }) {
        Text(this.sectionTitle()).width('100%').fontSize(this.phone ? 20 : 22)
          .fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
        Text($r('app.string.help_center_description')).width('100%').fontSize(12)
          .fontColor(ColorTokens.textTertiary).margin({ bottom: SpacingTokens.x2 })
        this.sectionContent()
      }
      .width('100%')
      .padding({ left: this.phone ? SpacingTokens.x4 : 40, right: this.phone ? SpacingTokens.x4 : 40,
        top: this.phone ? SpacingTokens.x4 : 30, bottom: 40 })
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1).height('100%').align(Alignment.TopStart)
    .backgroundColor(ColorTokens.bgWorkspace)
  }

  build() {
    if (this.phone) {
      Column() {
        Scroll() {
          Row({ space: SpacingTokens.x2 }) {
            this.sectionNavigation(true)
          }.padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
        }
        .width('100%').height(56).scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
        .backgroundColor(ColorTokens.bgSidebar)
        this.contentArea()
      }.width('100%').height('100%')
    } else {
      Row() {
        Column() {
          Text($r('app.string.help_center_title')).fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary).width('100%').height(48).padding({ left: SpacingTokens.x3 })
          this.sectionNavigation(false)
          Blank()
        }
        .width(220).height('100%').padding(SpacingTokens.x2).backgroundColor(ColorTokens.bgSidebar)
        .border({ width: { right: 1 }, color: ColorTokens.borderSubtle })
        this.contentArea()
      }.width('100%').height('100%')
    }
  }
}
