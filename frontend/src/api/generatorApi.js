// API for Generator Management System
import api from './axios';

export const generatorApi = {
    // Submit daily log ?" payload can include submitted_hours (meter), manual_hours, or both
    addDailyLog: async (generatorId, payload, date) => {
        const body = { generator_id: generatorId, date, ...payload };
        console.log("SENDING TO addDailyLog:", body);
        try {
            const response = await api.post('/generator/addDailyLog', body);
            return response.data;
        } catch (error) {
            throw new Error(error.response?.data?.error || 'Failed to submit log');
        }
    },

    // Fetch month logs
    getMonthLogs: async (generatorId, date) => {
        try {
            const response = await api.get(`/generator/getMonthLogs?generator_id=${generatorId}&date=${date}`);
            return response.data;
        } catch (error) {
            throw new Error('Failed to fetch logs');
        }
    },

    // Verify log
    verifyLog: async (logId) => {
        try {
            const response = await api.post('/generator/verifyLog', { log_id: logId });
            return response.data;
        } catch (error) {
            throw new Error('Failed to verify log');
        }
    },

    // Run AI analysis
    runAnalysis: async (logId) => {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), 120000); // 2 min timeout
        try {
            const response = await api.post(`/generator/runAnalysis?log_id=${logId}`, null, {
                signal: controller.signal
            });
            clearTimeout(timer);
            return response.data;
        } catch (err) {
            clearTimeout(timer);
            if (err.name === 'AbortError' || err.code === 'ERR_CANCELED') throw new Error('AI Analysis timed out after 2 minutes. Please try again.');
            throw new Error(err.response?.data?.error || `Server error ${err.response?.status}`);
        }
    },

    // Update actual fuel (admin override)
    updateActualFuel: async (logId, actualFuel) => {
        try {
            const response = await api.post('/generator/updateActualFuel', { log_id: logId, actual_fuel: actualFuel });
            return response.data;
        } catch (error) {
            throw new Error('Failed to update actual fuel');
        }
    }
};
