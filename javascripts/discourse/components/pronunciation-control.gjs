import { popupAjaxError } from "discourse/lib/ajax-error";
import i18n from "discourse-common/helpers/i18n";
import concatClass from "discourse/helpers/concat-class";
import not from "truth-helpers/helpers/not";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { bind } from "discourse-common/utils/decorators";
import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import DButton from "discourse/components/d-button";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { cancel, later } from "@ember/runloop";

const MAX_DURATION_SECONDS = 5;

export default class PronunciationControl extends Component {
  mediaRecorder = null;

  isUserMediaSupported = navigator.mediaDevices?.getUserMedia;

  chunks = [];

  @tracked isRecording = false;

  willDestroy() {
    super.willDestroy(...arguments);

    cancel(this.maxDurationHandler);
  }

  @action
  registerAudioNode(element) {
    this.audioNode = element;

    // TODO
    // we should set the src attribute to the audio file uploaded by the user
    // if it exists
  }

  @action
  async stop() {
    cancel(this.maxDurationHandler);
    this.mediaRecorder.stop();
    this.isRecording = false;
  }

  @action
  async delete() {
    this.audioNode.src = "";
  }

  @action
  async record() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: true,
      });

      this.mediaRecorder = new MediaRecorder(stream);
      this.mediaRecorder.ondataavailable = this.onDataAvailable;
      this.mediaRecorder.onstop = this.onStop;
      this.mediaRecorder.start();

      this.maxDurationHandler = later(this.stop, MAX_DURATION_SECONDS * 1000);

      this.isRecording = true;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @bind
  onDataAvailable(event) {
    this.chunks.push(event.data);
  }

  @bind
  onStop(event) {
    const blob = new Blob(this.chunks, { type: this.mediaRecorder.mimeType });
    this.chunks = [];
    const audioURL = window.URL.createObjectURL(blob);
    this.audioNode.src = audioURL;

    // TODO
    // we should set some property on user model to be able to save this upload
    // when user saves the profile
  }

  <template>
    {{#if this.isUserMediaSupported}}
      <div class="control-group pronunciation-control">
        <label class="control-label">Something</label>
        <div class="controls">
          <div class="pronunciation-control__audio">
            <audio controls {{didInsert this.registerAudioNode}}></audio>
          </div>

          <div class="pronunciation-control__actions">
            <DButton
              @disabled={{this.isRecording}}
              @translatedLabel={{i18n (themePrefix "record")}}
              @action={{this.record}}
              @icon="play"
              class={{concatClass
                (if this.isRecording "btn-danger" "btn-default")
              }}
            />
            <DButton
              @disabled={{not this.isRecording}}
              @translatedLabel={{i18n (themePrefix "stop")}}
              @icon="square"
              @action={{this.stop}}
            />
            <DButton
              @disabled={{this.isRecording}}
              @icon="trash-alt"
              @action={{this.delete}}
              class="btn-danger"
            />
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}