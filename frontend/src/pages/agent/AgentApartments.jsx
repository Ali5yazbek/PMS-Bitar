import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import axios from "../../api/axios";
import {
  Home, Camera, Check, ChevronRight, Clock, AlertTriangle,
  CheckCircle2, Zap, DollarSign, Upload, ShieldCheck
} from "lucide-react";

// --- helpers -------------------------------------------------------------------
const isFixed = (apt) =>
  apt.subscription_type === "Fixed Monthly" || apt.subscription_type === "Fixed Amp";

const isOnCooldown = (apt) => {
  if (apt.days_since_last_reading === null || apt.days_since_last_reading === undefined) return false;
  return parseInt(apt.days_since_last_reading) < 7;
};

const daysLeft = (apt) => Math.max(0, 7 - parseInt(apt.days_since_last_reading));

// --- Fixed Subscription Form ------------------------------------------------
const FixedForm = ({ apt, onSuccess }) => {
  const queryClient = useQueryClient();
  const [notes, setNotes]     = useState("");
  const [photo, setPhoto]     = useState(null);
  const [success, setSuccess] = useState(null);

  const mutation = useMutation({
    mutationFn: async () => {
      const fd = new FormData();
      fd.append("apartment_id", apt.apartment_id);
      fd.append("notes", notes);
      if (photo) fd.append("meter_photo", photo);
      return axios.post("/energy/agent/apartment-reading", fd, {
        headers: { "Content-Type": "multipart/form-data" },
      });
    },
    onSuccess: (res) => {
      const amount = res.data?.bill_amount ?? apt.monthly_fee;
      setSuccess(
        `Fixed payment of ${amount ? parseFloat(amount).toLocaleString() : ""} CFA submitted for admin approval!`
      );
      setNotes(""); setPhoto(null);
      queryClient.invalidateQueries(["agent_building_apartments"]);
      setTimeout(() => { setSuccess(null); onSuccess(); }, 3000);
    },
    onError: (err) => {
      const d = err.response?.data;
      if (d?.error === "duplicate") {
        alert("A fixed payment was already submitted for this apartment this month.");
      } else {
        alert(d?.message || d?.error || "Submission failed.");
      }
    },
  });

  if (success) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-4">
        <div className="w-20 h-20 bg-success/10 rounded-full flex items-center justify-center animate-pulse">
          <CheckCircle2 size={40} className="text-success" />
        </div>
        <p className="text-xl font-bold text-white text-center">{success}</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Fixed Amount Card */}
      <div className="bg-gradient-to-br from-indigo-500/20 to-purple-500/20 border border-indigo-500/30 rounded-2xl p-6 flex items-center justify-between">
        <div>
          <p className="text-xs text-slate-400 mb-1 uppercase tracking-wider font-medium">Fixed Monthly Subscription</p>
          <p className="text-4xl font-black text-white">
            {apt.monthly_fee ? parseFloat(apt.monthly_fee).toLocaleString() : "—"}
            <span className="text-lg text-slate-400 font-normal ml-2">CFA</span>
          </p>
          <p className="text-xs text-slate-500 mt-1">Amount is set by admin — no meter count needed</p>
        </div>
        <div className="w-16 h-16 bg-indigo-500/20 rounded-2xl flex items-center justify-center">
          <DollarSign size={32} className="text-indigo-400" />
        </div>
      </div>

      {/* Info banner */}
      <div className="flex items-start gap-3 p-4 bg-info/10 border border-info/20 rounded-xl">
        <ShieldCheck size={20} className="text-info shrink-0 mt-0.5" />
        <div>
          <p className="text-sm font-semibold text-info">Fixed Plan — Confirm Payment</p>
          <p className="text-xs text-slate-400 mt-1">
            Just confirm that this month&apos;s fixed payment is due. No meter reading needed.
            The admin will approve and generate the invoice automatically.
          </p>
        </div>
      </div>

      {/* Optional photo */}
      <div>
        <p className="text-sm font-medium text-muted mb-3">
          Proof Photo <span className="text-slate-500">(Optional)</span>
        </p>
        <div className="flex items-center gap-4">
          <label
            htmlFor="fixed-photo"
            className="cursor-pointer flex items-center gap-2 px-4 py-2.5 bg-slate-800 hover:bg-slate-700 border border-slate-600 rounded-xl text-slate-300 hover:text-white transition-all text-sm"
          >
            <Upload size={15} />
            {photo ? "Change Photo" : "Upload Photo (optional)"}
          </label>
          {photo && (
            <span className="text-sm font-medium text-success flex items-center gap-1">
              <Check size={14} /> {photo.name}
            </span>
          )}
          <input
            type="file" id="fixed-photo" accept="image/*" capture="environment"
            className="hidden" onChange={(e) => setPhoto(e.target.files[0])}
          />
        </div>
      </div>

      {/* Notes */}
      <div>
        <label className="block text-sm font-medium text-muted mb-2">Notes (Optional)</label>
        <textarea
          rows={2} value={notes} onChange={(e) => setNotes(e.target.value)}
          className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white text-sm focus:outline-none focus:border-primary transition-colors resize-none"
          placeholder="Any observations..."
        />
      </div>

      {/* Submit */}
      <button
        onClick={() => mutation.mutate()}
        disabled={mutation.isLoading}
        className="w-full py-4 rounded-xl font-bold text-lg flex items-center justify-center gap-2 bg-gradient-to-r from-indigo-500 to-purple-600 hover:from-indigo-600 hover:to-purple-700 text-white shadow-lg shadow-indigo-500/30 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {mutation.isLoading ? (
          <><div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" /> Submitting...</>
        ) : (
          <><CheckCircle2 size={20} /> Confirm Fixed Payment</>
        )}
      </button>
    </div>
  );
};

// --- Metered Subscription Form -----------------------------------------------
const MeteredForm = ({ apt, onSuccess }) => {
  const queryClient = useQueryClient();
  const [currentReading, setCurrentReading] = useState("");
  const [notes, setNotes]                   = useState("");
  const [photo, setPhoto]                   = useState(null);
  const [cooldownError, setCooldownError]   = useState(null);
  const [success, setSuccess]               = useState(null);

  const onCooldown = isOnCooldown(apt);

  const mutation = useMutation({
    mutationFn: async () => {
      if (!photo) throw new Error("Electricity Meter Photo is mandatory.");
      if (!currentReading) throw new Error("Current reading is required.");
      const fd = new FormData();
      fd.append("apartment_id", apt.apartment_id);
      fd.append("current_reading", currentReading);
      fd.append("notes", notes);
      fd.append("meter_photo", photo);
      return axios.post("/energy/agent/apartment-reading", fd, {
        headers: { "Content-Type": "multipart/form-data" },
      });
    },
    onSuccess: (res) => {
      const d = res.data;
      setSuccess(
        `Reading submitted! Consumption: ${parseFloat(d?.consumption ?? 0).toFixed(1)} kWh — awaiting admin review.`
      );
      setCurrentReading(""); setNotes(""); setPhoto(null); setCooldownError(null);
      queryClient.invalidateQueries(["agent_building_apartments"]);
      setTimeout(() => { setSuccess(null); onSuccess(); }, 3500);
    },
    onError: (err) => {
      const d = err.response?.data;
      if (d?.error === "cooldown") {
        setCooldownError(d);
      } else {
        alert(err.message || d?.error || d?.message || "Submission failed.");
      }
    },
  });

  if (success) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-4">
        <div className="w-20 h-20 bg-success/10 rounded-full flex items-center justify-center animate-pulse">
          <CheckCircle2 size={40} className="text-success" />
        </div>
        <p className="text-xl font-bold text-white text-center">{success}</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {onCooldown && (
        <div className="p-4 rounded-xl bg-warning/10 border border-warning/30 flex items-start gap-3">
          <AlertTriangle size={20} className="text-warning mt-0.5 shrink-0" />
          <div>
            <p className="font-semibold text-warning mb-1">Reading Not Available Yet</p>
            <p className="text-sm text-slate-300">
              A reading was submitted on <strong className="text-white">{apt.last_reading_date}</strong>.{" "}
              Next reading allowed in <strong className="text-warning">{daysLeft(apt)} day(s)</strong>.
            </p>
            <p className="text-xs text-slate-500 mt-1">Readings can only be submitted once every 7 days.</p>
          </div>
        </div>
      )}
      {cooldownError && (
        <div className="p-4 rounded-xl bg-danger/10 border border-danger/30 flex items-start gap-3">
          <AlertTriangle size={20} className="text-danger mt-0.5 shrink-0" />
          <div>
            <p className="font-semibold text-danger mb-1">Submission Blocked</p>
            <p className="text-sm text-slate-300">{cooldownError.message}</p>
          </div>
        </div>
      )}

      <fieldset disabled={onCooldown} className="disabled:opacity-40 disabled:pointer-events-none space-y-6">
        {/* Previous reading */}
        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex justify-between items-center">
          <div>
            <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Previous Reading</p>
            <p className="text-2xl font-bold text-white">
              {apt.last_reading || 0}{" "}
              <span className="text-sm font-normal text-slate-400">kWh</span>
            </p>
          </div>
          <div className="text-right">
            <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Last Updated</p>
            <p className="text-white font-medium">{apt.last_reading_date || "N/A"}</p>
          </div>
        </div>

        {/* Current reading */}
        <div>
          <label className="block text-sm font-medium text-muted mb-2">
            Current Reading (kWh) <span className="text-danger">*</span>
          </label>
          <input
            type="number" value={currentReading}
            onChange={(e) => setCurrentReading(e.target.value)}
            className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-4 text-2xl font-bold text-white focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/30 transition-all"
            placeholder="e.g. 4500"
          />
          {currentReading && apt.last_reading && (
            <p className="mt-2 text-sm text-info">
              Consumption:{" "}
              <span className="font-bold">
                {Math.max(0, parseFloat(currentReading) - parseFloat(apt.last_reading)).toFixed(1)} kWh
              </span>
            </p>
          )}
        </div>

        {/* Mandatory photo */}
        <div className="border-t border-slate-700/50 pt-5">
          <h3 className="text-sm font-semibold text-white mb-3 flex items-center gap-2">
            <Camera size={15} className="text-primary" />
            Photographic Proof <span className="text-danger text-xs">*</span>
          </h3>
          <label
            htmlFor="apt-photo-upload"
            className={`flex flex-col items-center justify-center w-full h-32 border-2 border-dashed rounded-xl cursor-pointer transition-all group ${
              photo ? "border-success/50 bg-success/5" : "border-slate-600 hover:border-primary hover:bg-primary/5"
            }`}
          >
            {photo ? (
              <div className="flex flex-col items-center gap-2">
                <CheckCircle2 size={28} className="text-success" />
                <p className="text-sm font-medium text-success">{photo.name}</p>
                <p className="text-xs text-slate-400">Click to change</p>
              </div>
            ) : (
              <div className="flex flex-col items-center gap-2">
                <div className="w-10 h-10 rounded-full bg-primary/10 group-hover:bg-primary/20 flex items-center justify-center transition-colors">
                  <Upload size={18} className="text-primary" />
                </div>
                <p className="text-sm text-slate-300">Click to upload meter photo</p>
                <p className="text-xs text-slate-500">JPG, PNG, HEIC • Required</p>
              </div>
            )}
          </label>
          <input
            type="file" accept="image/*" capture="environment"
            className="hidden" id="apt-photo-upload"
            onChange={(e) => setPhoto(e.target.files[0])}
          />
        </div>

        {/* Notes */}
        <div>
          <label className="block text-sm font-medium text-muted mb-2">Notes / Observations</label>
          <textarea
            rows={2} value={notes} onChange={(e) => setNotes(e.target.value)}
            className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white text-sm focus:outline-none focus:border-primary transition-colors resize-none"
            placeholder="Meter condition, anomalies..."
          />
        </div>

        {/* Submit */}
        <button
          onClick={() => mutation.mutate()}
          disabled={mutation.isLoading || !currentReading || !photo}
          className="w-full py-4 rounded-xl font-bold text-lg flex items-center justify-center gap-2 bg-gradient-to-r from-primary to-indigo-600 hover:from-primary/90 hover:to-indigo-700 text-white shadow-lg shadow-primary/30 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {mutation.isLoading ? (
            <><div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" /> Submitting...</>
          ) : (
            <><Zap size={20} /> Submit Meter Reading</>
          )}
        </button>
      </fieldset>
    </div>
  );
};

// --- Main Page -----------------------------------------------------------------
const AgentApartments = () => {
  const [selectedBuilding, setSelectedBuilding]   = useState(null);
  const [selectedApartment, setSelectedApartment] = useState(null);

  const { data: buildings = [], isLoading: buildingsLoading } = useQuery({
    queryKey: ["buildings"],
    queryFn: async () => (await axios.get("/buildings")).data,
  });

  const { data: apartments = [], isLoading: apartmentsLoading } = useQuery({
    queryKey: ["agent_building_apartments", selectedBuilding?.id],
    queryFn: async () =>
      (await axios.get(`/energy/agent/building-apartments/${selectedBuilding.id}`)).data,
    enabled: !!selectedBuilding,
  });

  const handleSuccess = () => setSelectedApartment(null);

  const apt       = selectedApartment;
  const aptFixed  = apt ? isFixed(apt) : false;

  return (
    <div className="p-8 max-w-7xl mx-auto h-full flex flex-col overflow-y-auto custom-scrollbar">
      <div className="mb-8 shrink-0">
        <h1 className="text-3xl font-bold text-white mb-2 flex items-center gap-3">
          <div className="w-10 h-10 bg-primary/20 text-primary rounded-xl flex items-center justify-center">
            <Home size={22} />
          </div>
          Submit Apartment Reading
        </h1>
        <p className="text-muted text-sm">
          Select a building and an apartment to submit the monthly electricity reading.
        </p>
      </div>

      <div className="flex flex-col lg:flex-row gap-8 flex-1 min-h-0">

        {/* -- Sidebar ----------------------------------------------------- */}
        <div className="w-full lg:w-1/3 flex flex-col gap-6">

          {/* Buildings */}
          <div className="flex flex-col glass-card max-h-[38vh] overflow-hidden">
            <div className="p-4 border-b border-slate-700/50 bg-slate-800/30">
              <h2 className="font-bold text-white uppercase text-xs tracking-widest">1. Select Building</h2>
            </div>
            <div className="flex-1 overflow-y-auto p-2 space-y-1">
              {buildingsLoading ? (
                <div className="p-4 text-center text-slate-500">Loading...</div>
              ) : buildings.length === 0 ? (
                <div className="p-4 text-center text-slate-500">No buildings found.</div>
              ) : buildings.map((b) => (
                <button
                  key={b.id}
                  onClick={() => { setSelectedBuilding(b); setSelectedApartment(null); }}
                  className={`w-full text-left p-3.5 rounded-xl transition-all flex justify-between items-center ${
                    selectedBuilding?.id === b.id
                      ? "bg-primary text-white shadow-lg shadow-primary/20"
                      : "text-slate-300 hover:bg-slate-800 hover:text-white"
                  }`}
                >
                  <span className="font-medium">{b.name}</span>
                  <ChevronRight size={15} className={selectedBuilding?.id === b.id ? "text-white" : "text-slate-500"} />
                </button>
              ))}
            </div>
          </div>

          {/* Apartments */}
          {selectedBuilding && (
            <div className="flex flex-col glass-card flex-1 overflow-hidden">
              <div className="p-4 border-b border-slate-700/50 bg-slate-800/30">
                <h2 className="font-bold text-white uppercase text-xs tracking-widest">2. Select Apartment</h2>
              </div>
              <div className="flex-1 overflow-y-auto p-2 space-y-1">
                {apartmentsLoading ? (
                  <div className="p-4 text-center text-slate-500">Loading...</div>
                ) : apartments.length === 0 ? (
                  <div className="p-4 text-center text-slate-500">No apartments found.</div>
                ) : apartments.map((a) => {
                  const fixed     = isFixed(a);
                  const cooldown  = !fixed && isOnCooldown(a);
                  const isSel     = selectedApartment?.apartment_id === a.apartment_id;
                  return (
                    <button
                      key={a.apartment_id}
                      onClick={() => setSelectedApartment(a)}
                      className={`w-full text-left p-3.5 rounded-xl transition-all flex justify-between items-center ${
                        isSel
                          ? "bg-indigo-500 text-white shadow-lg shadow-indigo-500/20"
                          : cooldown
                            ? "text-slate-500 hover:bg-slate-800/50 opacity-60"
                            : "text-slate-300 hover:bg-slate-800 hover:text-white"
                      }`}
                    >
                      <div>
                        <div className="font-medium flex items-center gap-2 text-sm">
                          Apt {a.apartment_code}
                          {a.subscription_type && (
                            <span className={`text-[9px] px-1.5 py-0.5 rounded font-bold ${
                              fixed ? "bg-info/30 text-info" : "bg-primary/30 text-primary"
                            }`}>
                              {fixed ? "FIXED" : "METERED"}
                            </span>
                          )}
                          {cooldown && (
                            <span className="text-[9px] px-1.5 py-0.5 rounded font-bold bg-warning/20 text-warning flex items-center gap-0.5">
                              <Clock size={8} /> {daysLeft(a)}d
                            </span>
                          )}
                        </div>
                        <div className="text-xs opacity-70 mt-0.5">{a.tenant_name || "No tenant"}</div>
                      </div>
                      <div>
                        {cooldown
                          ? <Clock size={13} className="text-warning" />
                          : <ChevronRight size={14} className={isSel ? "text-white" : "text-slate-500"} />
                        }
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        {/* -- Form Panel ------------------------------------------------ */}
        <div className="w-full lg:w-2/3 glass-card overflow-y-auto p-6">
          {!apt ? (
            <div className="h-full flex flex-col items-center justify-center text-slate-500 gap-4">
              <div className="w-16 h-16 bg-slate-800/50 rounded-2xl flex items-center justify-center">
                <Home size={30} className="opacity-40" />
              </div>
              <p className="text-sm">Select an apartment to submit a reading.</p>
            </div>
          ) : (
            <div>
              {/* Header */}
              <div className="mb-6 pb-4 border-b border-slate-700/50 flex justify-between items-start">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <h2 className="text-2xl font-bold text-white">Apt {apt.apartment_code}</h2>
                    <span className={`text-xs px-2.5 py-1 rounded-full font-bold border ${
                      aptFixed
                        ? "bg-info/20 text-info border-info/30"
                        : "bg-primary/20 text-primary border-primary/30"
                    }`}>
                      {aptFixed ? "?? FIXED" : "? METERED"}
                    </span>
                  </div>
                  <p className="text-sm text-muted">Tenant: {apt.tenant_name || "N/A"}</p>
                </div>
                {aptFixed ? (
                  <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold bg-info/10 text-info border border-info/20">
                    <DollarSign size={11} /> Fixed Plan
                  </span>
                ) : isOnCooldown(apt) ? (
                  <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold bg-warning/10 text-warning border border-warning/20">
                    <Clock size={11} /> Cooldown: {daysLeft(apt)}d left
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold bg-warning/10 text-warning border border-warning/20">
                    ?? Reading Due
                  </span>
                )}
              </div>

              {aptFixed
                ? <FixedForm apt={apt} onSuccess={handleSuccess} />
                : <MeteredForm apt={apt} onSuccess={handleSuccess} />
              }
            </div>
          )}
        </div>

      </div>
    </div>
  );
};

export default AgentApartments;
