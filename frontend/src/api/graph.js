import service, { requestWithRetry } from './index'

/**
 * GenerateOntology（UploadDocs和SimRequirements）
 * @param {Object} data - Containsfiles, simulation_requirement, project_name等
 * @returns {Promise}
 */
export function generateOntology(formData) {
  return requestWithRetry(() => 
    service({
      url: '/api/graph/ontology/generate',
      method: 'post',
      data: formData,
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
  )
}

/**
 * BuildGraph
 * @param {Object} data - Containsproject_id, graph_name等
 * @returns {Promise}
 */
export function buildGraph(data) {
  return requestWithRetry(() =>
    service({
      url: '/api/graph/build',
      method: 'post',
      data
    })
  )
}

/**
 * Query TaskStatus
 * @param {String} taskId - TaskID
 * @returns {Promise}
 */
export function getTaskStatus(taskId) {
  return service({
    url: `/api/graph/task/${taskId}`,
    method: 'get'
  })
}

/**
 * Fetch Graph Data
 * @param {String} graphId - GraphID
 * @returns {Promise}
 */
export function getGraphData(graphId) {
  return service({
    url: `/api/graph/data/${graphId}`,
    method: 'get'
  })
}

/**
 * FetchProjectInfo
 * @param {String} projectId - ProjectID
 * @returns {Promise}
 */
export function getProject(projectId) {
  return service({
    url: `/api/graph/project/${projectId}`,
    method: 'get'
  })
}

/**
 * List all projects
 * @returns {Promise}
 */
export function listProjects() {
  return service({
    url: '/api/graph/project/list',
    method: 'get'
  })
}

/**
 * Delete a project
 * @param {String} projectId - ProjectID
 * @returns {Promise}
 */
export function deleteProject(projectId) {
  return service({
    url: `/api/graph/project/${projectId}`,
    method: 'delete'
  })
}
