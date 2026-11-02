import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { useTranslation } from 'react-i18next';
import { Users as UsersIcon, Plus, Edit2, Trash2, Shield, AlertCircle, X } from 'lucide-react';

const Users = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  
  const [formData, setFormData] = useState({
    name: '',
    username: '',
    email: '',
    password: '',
    role: 'cashier',
    phone: '',
    national_id: ''
  });

  const { data: users, isLoading } = useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      const res = await axios.get('/users');
      return res.data;
    }
  });

  const createMutation = useMutation({
    mutationFn: async (data) => {
      return axios.post('/users', data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['users']);
      closeModal();
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to create user');
    }
  });

  const updateMutation = useMutation({
    mutationFn: async ({ id, data }) => {
      return axios.put(`/users/${id}`, data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['users']);
      closeModal();
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to update user');
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async (id) => {
      return axios.delete(`/users/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['users']);
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to delete user');
    }
  });

  const openModal = (user = null) => {
    if (user) {
      setEditingUser(user);
      setFormData({
        name: user.name,
        username: user.username || '',
        email: user.email,
        password: '', // Don't populate password
        role: user.role,
        phone: user.phone || '',
        national_id: user.national_id || ''
      });
    } else {
      setEditingUser(null);
      setFormData({
        name: '',
        username: '',
        email: '',
        password: '',
        role: 'cashier',
        phone: '',
        national_id: ''
      });
    }
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setEditingUser(null);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (editingUser) {
      updateMutation.mutate({ id: editingUser.id, data: formData });
    } else {
      createMutation.mutate(formData);
    }
  };

  const handleDelete = (id) => {
    if (window.confirm(t('users.confirm_del'))) {
      deleteMutation.mutate(id);
    }
  };

  return (
    <div className="p-8 max-w-7xl mx-auto h-full flex flex-col">
      <div className="flex justify-between items-center mb-8 shrink-0">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">{t('users.title')}</h1>
          <p className="text-muted">{t('users.subtitle')}</p>
        </div>
        <button 
          onClick={() => openModal()}
          className="btn-primary px-6 py-2 rounded-xl flex items-center shadow-lg shadow-primary/20 hover:shadow-primary/40 transition-all"
        >
          <Plus size={20} className="me-2" />
          {t('users.btn_add')}
        </button>
      </div>

      <div className="glass-card flex-1 overflow-hidden flex flex-col">
        {isLoading ? (
          <div className="p-8 text-white flex justify-center items-center h-full">{t('users.loading')}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-start border-collapse">
              <thead>
                <tr className="border-b border-slate-700/50 bg-slate-800/30">
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">{t('users.th_name')}</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">{t('users.th_email')}</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">{t('users.th_role')}</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">{t('users.th_created')}</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-end">{t('users.th_actions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {users?.map((user) => (
                  <tr key={user.id} className="hover:bg-slate-800/30 transition-colors">
                    <td className="p-4">
                      <div className="flex items-center">
                        <div className="w-8 h-8 rounded-full bg-primary/20 text-primary flex items-center justify-center me-3 font-bold">
                          {user.name.charAt(0).toUpperCase()}
                        </div>
                        <span className="text-white font-medium">{user.name}</span>
                      </div>
                    </td>
                    <td className="p-4 text-slate-300">{user.email}</td>
                    <td className="p-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-medium border flex items-center w-max ${
                        user.role === 'admin' ? 'bg-danger/10 text-danger border-danger/20' :
                        user.role === 'manager' ? 'bg-primary/10 text-primary border-primary/20' :
                        user.role === 'cashier' ? 'bg-success/10 text-success border-success/20' :
                        user.role === 'agent' ? 'bg-indigo-500/10 text-indigo-400 border-indigo-500/20' :
                        'bg-warning/10 text-warning border-warning/20'
                      }`}>
                        {user.role === 'admin' && <Shield size={12} className="me-1" />}
                        {user.role === 'agent' ? 'Utility Agent' : user.role === 'tenant' ? 'Tenant' : (t(`users.role_${user.role}`) !== `users.role_${user.role}` ? t(`users.role_${user.role}`) : (user.role.charAt(0).toUpperCase() + user.role.slice(1)))}
                      </span>
                    </td>
                    <td className="p-4 text-slate-400 text-sm">
                      {new Date(user.created_at).toLocaleDateString()}
                    </td>
                    <td className="p-4 text-end">
                      <button 
                        onClick={() => openModal(user)}
                        className="p-2 text-slate-400 hover:text-primary transition-colors inline-block"
                        title="Edit User"
                      >
                        <Edit2 size={18} />
                      </button>
                      {user.id !== 1 && ( // Prevent deleting primary admin visually
                        <button 
                          onClick={() => handleDelete(user.id)}
                          className="p-2 text-slate-400 hover:text-danger transition-colors inline-block ms-2"
                          title="Delete User"
                        >
                          <Trash2 size={18} />
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
                {(!users || users.length === 0) && (
                  <tr>
                    <td colSpan="5" className="p-8 text-center text-muted">{t('users.no_users')}</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="glass-panel w-full max-w-md overflow-hidden flex flex-col animate-in zoom-in-95 duration-200">
            <div className="flex justify-between items-center p-6 border-b border-slate-700/50">
              <h2 className="text-xl font-bold text-white flex items-center">
                <UsersIcon size={20} className="me-2 text-primary" />
                {editingUser ? t('users.modal_edit') : t('users.modal_add')}
              </h2>
              <button onClick={closeModal} className="text-slate-400 hover:text-white transition-colors">
                <X size={24} />
              </button>
            </div>
            
            <form onSubmit={handleSubmit} className="p-6">
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">{t('users.label_name')}</label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({...formData, name: e.target.value})}
                    className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-primary transition-colors"
                    placeholder="e.g. John Doe"
                    autoComplete="off"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-muted mb-1">Username</label>
                  <input
                    type="text"
                    value={formData.username}
                    onChange={(e) => setFormData({...formData, username: e.target.value})}
                    className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-primary transition-colors"
                    placeholder="e.g. johndoe"
                    autoComplete="off"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">{t('users.label_email')}</label>
                  <input
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({...formData, email: e.target.value})}
                    className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-primary transition-colors"
                    placeholder="john@example.com"
                    autoComplete="off"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">
                    {t('users.label_pass')} {editingUser && <span className="text-slate-500 text-xs font-normal">{t('users.pass_hint')}</span>}
                  </label>
                  <input
                    type="password"
                    required={!editingUser}
                    value={formData.password}
                    onChange={(e) => setFormData({...formData, password: e.target.value})}
                    className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-primary transition-colors"
                    placeholder="••••••••"
                    autoComplete="new-password"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-muted mb-1">{t('users.label_role')}</label>
                  <select
                    value={formData.role}
                    onChange={(e) => setFormData({...formData, role: e.target.value})}
                    className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-primary transition-colors appearance-none"
                  >
                    <option value="admin" className="bg-slate-900 text-white">{t('users.role_admin')}</option>
                    <option value="manager" className="bg-slate-900 text-white">{t('users.role_manager')}</option>
                    <option value="cashier" className="bg-slate-900 text-white">{t('users.role_cashier')}</option>
                    <option value="maintenance" className="bg-slate-900 text-white">{t('users.role_maintenance')}</option>
                    <option value="agent" className="bg-slate-900 text-white">Utility Agent</option>
                    <option value="tenant" className="bg-slate-900 text-white">Tenant</option>
                  </select>
                </div>
                
                {formData.role === 'tenant' && (
                  <>
                    <div>
                      <label className="block text-sm font-medium text-muted mb-1">Phone Number</label>
                      <input
                        type="text"
                        required
                        value={formData.phone}
                        onChange={(e) => setFormData({...formData, phone: e.target.value})}
                        className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-primary transition-colors"
                        placeholder="Phone Number"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-muted mb-1">National ID / Passport</label>
                      <input
                        type="text"
                        required
                        value={formData.national_id}
                        onChange={(e) => setFormData({...formData, national_id: e.target.value})}
                        className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-primary transition-colors"
                        placeholder="National ID"
                      />
                    </div>
                  </>
                )}
              </div>

              {editingUser?.id === 1 && formData.role !== 'admin' && (
                <div className="mt-4 p-3 rounded-lg bg-warning/10 border border-warning/20 flex items-start">
                  <AlertCircle size={16} className="text-warning me-2 shrink-0 mt-0.5" />
                  <p className="text-xs text-warning">{t('users.warning_admin')}</p>
                </div>
              )}
              
              <div className="mt-8 flex justify-end gap-4">
                <button 
                  type="button" 
                  onClick={closeModal} 
                  className="px-6 py-2 rounded-xl text-white font-medium hover:bg-slate-800 transition-colors"
                >
                  {t('users.btn_cancel')}
                </button>
                <button 
                  type="submit" 
                  className="btn-primary px-8 py-2 rounded-xl"
                  disabled={createMutation.isLoading || updateMutation.isLoading}
                >
                  {createMutation.isLoading || updateMutation.isLoading ? t('users.btn_saving') : t('users.btn_save')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Users;
