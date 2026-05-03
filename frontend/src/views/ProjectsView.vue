<template>
  <div class="projects-container">
    <!-- Top Nav -->
    <nav class="navbar">
      <div class="nav-brand" @click="goHome">MIROFISH</div>
      <div class="nav-links">
        <router-link to="/" class="nav-link">New Project</router-link>
        <a href="https://github.com/666ghj/MiroFish" target="_blank" class="github-link">
          Visit GitHub <span class="arrow">↗</span>
        </a>
      </div>
    </nav>

    <div class="main-content">
      <div class="projects-header">
        <h1 class="page-title">Existing Projects</h1>
        <p class="page-desc">Manage and resume your simulation projects</p>
      </div>

      <div v-if="loading" class="loading-state">
        <div class="loading-spinner"></div>
        <span>Loading projects...</span>
      </div>

      <div v-else-if="error" class="error-state">
        <span class="error-icon">⚠</span>
        <span>{{ error }}</span>
      </div>

      <div v-else-if="projects.length === 0" class="empty-state">
        <div class="empty-icon">📁</div>
        <div class="empty-title">No projects yet</div>
        <div class="empty-hint">Create your first project from the home page</div>
        <button class="new-project-btn" @click="goHome">Create Project</button>
      </div>

      <div v-else class="projects-list">
        <div
          v-for="project in projects"
          :key="project.project_id"
          class="project-card"
          @click="openProject(project)"
        >
          <div class="project-card-main">
            <div class="project-top">
              <span class="project-name">{{ project.name }}</span>
              <span class="status-badge" :class="getStepBadge(project).class">
                {{ getStepBadge(project).label }}
              </span>
            </div>
            <div class="project-meta">
              <span class="project-id">{{ project.project_id }}</span>
              <span class="meta-divider">|</span>
              <span class="project-date">{{ formatDate(project.created_at) }}</span>
              <span v-if="project.total_text_length" class="meta-divider">|</span>
              <span v-if="project.total_text_length" class="project-chars">
                {{ project.total_text_length.toLocaleString() }} chars
              </span>
            </div>
            <div v-if="project.simulation_requirement" class="project-requirement">
              {{ project.simulation_requirement }}
            </div>
          </div>
          <div class="project-actions" @click.stop>
            <button
              class="delete-btn"
              @click="confirmDelete(project)"
              title="Delete project"
            >
              🗑
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Confirmation Dialog -->
    <div v-if="showConfirm" class="confirm-overlay" @click.self="cancelDelete">
      <div class="confirm-dialog">
        <div class="confirm-header">
          <span class="confirm-icon">⚠</span>
          <span>Delete Project?</span>
        </div>
        <p class="confirm-body">
          Are you sure you want to delete <strong>{{ projectToDelete?.name }}</strong>?
          <br>This action cannot be undone.
        </p>
        <div class="confirm-actions">
          <button class="confirm-cancel" @click="cancelDelete">Cancel</button>
          <button class="confirm-delete" @click="doDelete">Delete</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { listProjects, deleteProject } from '../api/graph'

const router = useRouter()

const projects = ref([])
const loading = ref(true)
const error = ref('')

const showConfirm = ref(false)
const projectToDelete = ref(null)

const stepBadgeMap = {
  step1: { label: 'Step 1: Graph Build', class: 'badge-step1' },
  step2: { label: 'Step 2: Environment Setup', class: 'badge-step2' },
  step3: { label: 'Step 3: Start Simulation', class: 'badge-step3' },
  step4: { label: 'Step 4: Report Generation', class: 'badge-step4' },
  step5: { label: 'Step 5: Deep Interaction', class: 'badge-step5' },
  failed: { label: 'Failed', class: 'badge-failed' }
}

const getStepBadge = (project) => {
  const step = project.current_step
  if (step?.status_key && stepBadgeMap[step.status_key]) {
    return stepBadgeMap[step.status_key]
  }
  return { label: step?.label || 'Unknown', class: 'badge-default' }
}

const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  try {
    const d = new Date(dateStr)
    return d.toLocaleString('en-US', {
      month: 'short', day: 'numeric', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    })
  } catch {
    return dateStr
  }
}

const goHome = () => router.push('/')

const openProject = (project) => {
  router.push({ name: 'Process', params: { projectId: project.project_id } })
}

const loadProjects = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await listProjects()
    if (res.success) {
      projects.value = res.data || []
    } else {
      error.value = res.error || 'Failed to load projects'
    }
  } catch (err) {
    error.value = 'Failed to load projects: ' + (err.message || 'Unknown error')
  } finally {
    loading.value = false
  }
}

const confirmDelete = (project) => {
  projectToDelete.value = project
  showConfirm.value = true
}

const cancelDelete = () => {
  showConfirm.value = false
  projectToDelete.value = null
}

const doDelete = async () => {
  if (!projectToDelete.value) return
  try {
    await deleteProject(projectToDelete.value.project_id)
    projects.value = projects.value.filter(
      p => p.project_id !== projectToDelete.value.project_id
    )
  } catch (err) {
    alert('Delete failed: ' + (err.message || 'Unknown error'))
  } finally {
    cancelDelete()
  }
}

onMounted(loadProjects)
</script>

<style scoped>
.projects-container {
  min-height: 100vh;
  background: #fff;
  font-family: var(--font-sans, 'Space Grotesk', system-ui, sans-serif);
  color: #000;
}

/* Top nav */
.navbar {
  height: 60px;
  background: #000;
  color: #fff;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 40px;
}

.nav-brand {
  font-family: var(--font-mono, 'JetBrains Mono', monospace);
  font-weight: 800;
  letter-spacing: 1px;
  font-size: 1.2rem;
  cursor: pointer;
}

.nav-links {
  display: flex;
  align-items: center;
  gap: 24px;
}

.nav-link {
  color: #fff;
  text-decoration: none;
  font-family: var(--font-mono, 'JetBrains Mono', monospace);
  font-size: 0.9rem;
  font-weight: 500;
  transition: opacity 0.2s;
}

.nav-link:hover {
  opacity: 0.8;
}

.github-link {
  color: #fff;
  text-decoration: none;
  font-family: var(--font-mono, 'JetBrains Mono', monospace);
  font-size: 0.9rem;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: opacity 0.2s;
}

.github-link:hover {
  opacity: 0.8;
}

.arrow {
  font-family: sans-serif;
}

/* Main content */
.main-content {
  max-width: 1000px;
  margin: 0 auto;
  padding: 60px 40px;
}

.projects-header {
  margin-bottom: 40px;
}

.page-title {
  font-size: 2.5rem;
  font-weight: 520;
  margin: 0 0 10px 0;
  letter-spacing: -1px;
}

.page-desc {
  color: #666;
  font-size: 1rem;
}

/* Loading / Empty / Error */
.loading-state,
.error-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 20px;
  gap: 16px;
  font-family: var(--font-mono, 'JetBrains Mono', monospace);
  color: #666;
}

.loading-spinner {
  width: 24px;
  height: 24px;
  border: 2px solid #eee;
  border-top-color: #000;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-icon {
  font-size: 1.5rem;
}

.empty-icon {
  font-size: 2.5rem;
  opacity: 0.4;
}

.empty-title {
  font-size: 1.2rem;
  font-weight: 600;
  color: #333;
}

.empty-hint {
  font-size: 0.85rem;
  color: #999;
}

.new-project-btn {
  margin-top: 10px;
  background: #000;
  color: #fff;
  border: none;
  padding: 12px 24px;
  font-family: var(--font-mono, 'JetBrains Mono', monospace);
  font-weight: 600;
  font-size: 0.85rem;
  cursor: pointer;
  transition: all 0.2s;
}

.new-project-btn:hover {
  background: #FF4500;
}

/* Projects list */
.projects-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.project-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border: 1px solid #e5e5e5;
  padding: 20px 24px;
  cursor: pointer;
  transition: all 0.2s;
  background: #fff;
}

.project-card:hover {
  border-color: #000;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
}

.project-card-main {
  flex: 1;
  min-width: 0;
}

.project-top {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}

.project-name {
  font-weight: 600;
  font-size: 1.05rem;
  color: #000;
}

.status-badge {
  font-family: var(--font-mono, 'JetBrains Mono', monospace);
  font-size: 0.7rem;
  font-weight: 700;
  padding: 3px 8px;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}

.badge-step1 {
  background: #f0f0f0;
  color: #444;
}

.badge-step2 {
  background: #e8f4fd;
  color: #0066cc;
}

.badge-step3 {
  background: #fff3e0;
  color: #e65100;
}

.badge-step4 {
  background: #f3e5f5;
  color: #7b1fa2;
}

.badge-step5 {
  background: #e8f5e9;
  color: #2e7d32;
}

.badge-failed {
  background: #ffebee;
  color: #c62828;
}

.badge-default {
  background: #f0f0f0;
  color: #666;
}

.project-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: var(--font-mono, 'JetBrains Mono', monospace);
  font-size: 0.75rem;
  color: #999;
  margin-bottom: 6px;
  flex-wrap: wrap;
}

.project-id {
  font-family: var(--font-mono, 'JetBrains Mono', monospace);
}

.meta-divider {
  color: #ddd;
}

.project-requirement {
  font-size: 0.85rem;
  color: #666;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.project-actions {
  margin-left: 16px;
  flex-shrink: 0;
}

.delete-btn {
  background: none;
  border: 1px solid #eee;
  padding: 6px 10px;
  cursor: pointer;
  font-size: 1rem;
  opacity: 0.5;
  transition: all 0.2s;
}

.delete-btn:hover {
  opacity: 1;
  border-color: #c62828;
  background: #ffebee;
}

/* Confirmation Dialog */
.confirm-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.confirm-dialog {
  background: #fff;
  border: 1px solid #000;
  padding: 28px 32px;
  max-width: 420px;
  width: 90%;
  box-shadow: 0 10px 40px rgba(0,0,0,0.15);
}

.confirm-header {
  font-family: var(--font-mono, 'JetBrains Mono', monospace);
  font-weight: 700;
  font-size: 1.1rem;
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 16px;
}

.confirm-icon {
  font-size: 1.3rem;
}

.confirm-body {
  font-size: 0.95rem;
  color: #444;
  line-height: 1.6;
  margin-bottom: 24px;
}

.confirm-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.confirm-cancel {
  background: none;
  border: 1px solid #ddd;
  padding: 10px 20px;
  font-family: var(--font-mono, 'JetBrains Mono', monospace);
  font-size: 0.85rem;
  cursor: pointer;
  transition: all 0.2s;
}

.confirm-cancel:hover {
  border-color: #000;
}

.confirm-delete {
  background: #c62828;
  color: #fff;
  border: none;
  padding: 10px 20px;
  font-family: var(--font-mono, 'JetBrains Mono', monospace);
  font-weight: 600;
  font-size: 0.85rem;
  cursor: pointer;
  transition: all 0.2s;
}

.confirm-delete:hover {
  background: #a00000;
}

/* Responsive */
@media (max-width: 640px) {
  .main-content {
    padding: 30px 20px;
  }

  .project-card {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .project-actions {
    margin-left: 0;
    width: 100%;
    display: flex;
    justify-content: flex-end;
  }
}
</style>
