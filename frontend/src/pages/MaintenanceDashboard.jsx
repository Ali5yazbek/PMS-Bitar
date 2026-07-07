import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { useTranslation } from 'react-i18next';
import { CheckCircle, Camera, AlertCircle, X } from 'lucide-react';

const MaintenanceDashboard = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [selectedTask, setSelectedTask] = useState(null);
  const [beforePhoto, setBeforePhoto] = useState(null);
  const [afterPhoto, setAfterPhoto] = useState(null);
  const [notes, setNotes] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  // Assume user is stored in local storage
  const user = JSON.parse(localStorage.getItem('user'));

  const { data: tasks, isLoading, error } = useQuery({
    queryKey: ['workerTasks'],
    queryFn: async () => {
      const res = await axios.get('/maintenance/tasks');
      return res.data;
    }
  });

  const submitMutation = useMutation({
    mutationFn: async (payload) => {
      return axios.post(`/maintenance/tasks/${payload.id}/submit`, payload);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['workerTasks']);
      closeModal();
    },
    onError: (err) => {
      setErrorMsg(err.response?.data?.error || 'Failed to submit task.');
    }
  });

  const handleFileChange = (e, setPhoto) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        // Create an image element to draw onto canvas
        const img = new Image();
        img.onload = () => {
          const canvas = document.createElement('canvas');
          const MAX_WIDTH = 800;
          const MAX_HEIGHT = 800;
          let width = img.width;
          let height = img.height;

          if (width > height) {
            if (width > MAX_WIDTH) {
              height *= MAX_WIDTH / width;
              width = MAX_WIDTH;
            }
          } else {
            if (height > MAX_HEIGHT) {
              width *= MAX_HEIGHT / height;
              height = MAX_HEIGHT;
            }
          }
          canvas.width = width;
          canvas.height = height;

          const ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0, width, height);

          // Compress to JPEG with 0.7 quality
          const dataUrl = canvas.toDataURL('image/jpeg', 0.7);
          setPhoto(dataUrl);
        };
        img.src = reader.result;
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!beforePhoto || !afterPhoto || !notes.trim()) {
      setErrorMsg(t('maintenance_worker.req_error'));
      return;
    }
    submitMutation.mutate({
      id: selectedTask.id,
      before_photo: beforePhoto,
      after_photo: afterPhoto,
      notes,
      worker_id: user?.id
    });
  };

  const closeModal = () => {
    setSelectedTask(null);
    setBeforePhoto(null);
    setAfterPhoto(null);
    setNotes('');
    setErrorMsg('');
  };

  if (isLoading) return <div className="p-8 text-white">Loading tasks...</div>;
  if (error) return <div className="p-8 text-danger">Error loading tasks.</div>;

  return (
    <div className="flex-1 overflow-y-auto p-8 hide-scrollbar bg-background h-full">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">{t('maintenance_worker.title')}</h1>
        <p className="text-muted">{t('maintenance_worker.subtitle')}</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {tasks && tasks.length > 0 ? tasks.map(task => (
          <div key={task.id} className="glass-card p-6 flex flex-col justify-between">
            <div>
              <div className="flex justify-between items-start mb-4">
                <span className={`px-3 py-1 rounded-full text-xs font-medium border ${
                  task.status === 'Rejected' ? 'bg-danger/20 text-danger border-danger/30' : 'bg-warning/20 text-warning border-warning/30'
                }`}>
                  {t(`maintenance.status_${task.status.toLowerCase()}`)}
                </span>
                <span className="text-muted text-sm">{task.scheduled_date}</span>
              </div>
              <h3 className="text-xl font-bold text-white mb-1">{t('maintenance.building')} {task.building_name}</h3>
              <p className="text-lg text-slate-300 mb-4">{t('maintenance.apt')} {task.apartment_code}</p>
              <div className="text-sm text-muted mb-6 flex items-center">
                <AlertCircle size={16} className="me-2" />
                {t('maintenance_worker.due')}
              </div>
            </div>
            <button 
              onClick={() => setSelectedTask(task)}
              className="w-full btn-primary py-2 flex items-center justify-center rounded-xl"
            >
              <CheckCircle size={18} className="me-2" /> {t('maintenance_worker.btn_complete')}
            </button>
          </div>
        )) : (
          <div className="col-span-full glass-card p-12 flex flex-col items-center justify-center text-center">
            <CheckCircle size={48} className="text-success mb-4 opacity-50" />
            <h3 className="text-xl font-bold text-white mb-2">{t('maintenance_worker.all_caught_up')}</h3>
            <p className="text-muted">{t('maintenance_worker.no_tasks')}</p>
          </div>
        )}
      </div>

      {/* Task Completion Modal */}
      {selectedTask && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="glass-panel w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="flex justify-between items-center p-6 border-b border-slate-700/50">
              <div>
                <h2 className="text-xl font-bold text-white">{t('maintenance_worker.modal_title')}</h2>
                <p className="text-muted text-sm">{t('maintenance.building')} {selectedTask.building_name} - {t('maintenance.apt')} {selectedTask.apartment_code}</p>
              </div>
              <button onClick={closeModal} className="text-slate-400 hover:text-white transition-colors">
                <X size={24} />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto hide-scrollbar flex-1">
              {errorMsg && (
                <div className="bg-danger/20 text-danger p-4 rounded-xl border border-danger/30 mb-6 flex items-center">
                  <AlertCircle size={20} className="me-3 shrink-0" />
                  {errorMsg}
                </div>
              )}

              <form id="task-form" onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* Before Photo */}
                  <div className="space-y-2">
                    <label className="block text-sm font-medium text-slate-300">{t('maintenance_worker.label_before')}</label>
                    <div className={`border-2 border-dashed ${beforePhoto ? 'border-primary/50 bg-primary/5' : 'border-slate-700 hover:border-slate-500'} rounded-xl p-4 text-center cursor-pointer transition-colors relative overflow-hidden h-48 flex items-center justify-center`}>
                      <input 
                        type="file" 
                        accept="image/*" 
                        onChange={(e) => handleFileChange(e, setBeforePhoto)} 
                        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                      />
                      {beforePhoto ? (
                        <img src={beforePhoto} alt="Before" className="w-full h-full object-cover rounded-lg" />
                      ) : (
                        <div className="flex flex-col items-center">
                          <Camera size={32} className="text-slate-400 mb-2" />
                          <span className="text-sm text-slate-400">{t('maintenance_worker.click_upload')}</span>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* After Photo */}
                  <div className="space-y-2">
                    <label className="block text-sm font-medium text-slate-300">{t('maintenance_worker.label_after')}</label>
                    <div className={`border-2 border-dashed ${afterPhoto ? 'border-success/50 bg-success/5' : 'border-slate-700 hover:border-slate-500'} rounded-xl p-4 text-center cursor-pointer transition-colors relative overflow-hidden h-48 flex items-center justify-center`}>
                      <input 
                        type="file" 
                        accept="image/*" 
                        onChange={(e) => handleFileChange(e, setAfterPhoto)} 
                        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                      />
                      {afterPhoto ? (
                        <img src={afterPhoto} alt="After" className="w-full h-full object-cover rounded-lg" />
                      ) : (
                        <div className="flex flex-col items-center">
                          <Camera size={32} className="text-slate-400 mb-2" />
                          <span className="text-sm text-slate-400">{t('maintenance_worker.click_upload')}</span>
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="block text-sm font-medium text-slate-300">{t('maintenance_worker.label_notes')}</label>
                  <textarea 
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder={t('maintenance_worker.placeholder_notes')}
                    className="w-full bg-slate-800/50 border border-slate-700 rounded-xl p-4 text-white placeholder:text-slate-500 focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary h-32 resize-none"
                    required
                  ></textarea>
                </div>
              </form>
            </div>
            
            <div className="p-6 border-t border-slate-700/50 flex justify-end gap-4 bg-slate-900/50">
              <button 
                type="button" 
                onClick={closeModal} 
                className="px-6 py-2 rounded-xl text-white font-medium hover:bg-slate-800 transition-colors"
                disabled={submitMutation.isLoading}
              >
                {t('maintenance_worker.btn_cancel')}
              </button>
              <button 
                type="submit" 
                form="task-form"
                className="btn-primary px-8 py-2 rounded-xl"
                disabled={submitMutation.isLoading}
              >
                {submitMutation.isLoading ? t('maintenance_worker.btn_submitting') : t('maintenance_worker.btn_submit')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MaintenanceDashboard;
