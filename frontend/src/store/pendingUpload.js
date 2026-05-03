/**
 * 临时存储待Upload's File和Requirements
 * Used forHomeClickLaunchEngine后Now跳转，在ProcessPage再ProceedAPIInvoke
 */
import { reactive } from 'vue'

const state = reactive({
  files: [],
  simulationRequirement: '',
  llmConfigs: null,
  isPending: false
})

export function setPendingUpload(files, requirement, llmConfigs = null) {
  state.files = files
  state.simulationRequirement = requirement
  state.llmConfigs = llmConfigs
  state.isPending = true
}

export function getPendingUpload() {
  return {
    files: state.files,
    simulationRequirement: state.simulationRequirement,
    llmConfigs: state.llmConfigs,
    isPending: state.isPending
  }
}

export function clearPendingUpload() {
  state.files = []
  state.simulationRequirement = ''
  state.llmConfigs = null
  state.isPending = false
}

export default state
