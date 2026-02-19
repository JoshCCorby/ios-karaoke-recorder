import { useState, useEffect, useRef } from 'react';
import './App.css';

// Mock RecorderViewModel
const useRecorderVM = () => {
  const [isRecording, setIsRecording] = useState(false);
  const [recordingTime, setRecordingTime] = useState(0);
  const [audioLevel, setAudioLevel] = useState(0);
  const [recordings, setRecordings] = useState<string[]>([]);
  const intervalRef = useRef<number | null>(null);

  useEffect(() => {
    if (isRecording) {
      intervalRef.current = window.setInterval(() => {
        setRecordingTime((t) => t + 0.1);
        setAudioLevel(Math.random()); // Random level 0-1
      }, 100);
    } else {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
      setAudioLevel(0);
    }
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [isRecording]);

  const startRecording = () => {
    setRecordingTime(0);
    setIsRecording(true);
  };

  const stopRecording = () => {
    setIsRecording(false);
    // Add mock recording
    setRecordings((prev) => [...prev, `Take ${prev.length + 1}.m4a`]);
  };

  const fetchRecordings = () => {
    // Simulated fetch
    setRecordings(['Take 1.m4a', 'Take 2.m4a']);
  };

  return { isRecording, recordingTime, audioLevel, recordings, startRecording, stopRecording, fetchRecordings };
};

// Mock PlaybackViewModel
const usePlaybackVM = () => {
  const [isPlayingBackingTrack, setIsPlayingBackingTrack] = useState(false);
  const [duration, setDuration] = useState(0); // 0 means no track loaded
  const [currentTime, setCurrentTime] = useState(0);
  const [backingTrackName, setBackingTrackName] = useState<string | null>(null);
  const intervalRef = useRef<number | null>(null);

  useEffect(() => {
    if (isPlayingBackingTrack && duration > 0) {
      intervalRef.current = window.setInterval(() => {
        setCurrentTime((t) => {
          if (t >= duration) {
            setIsPlayingBackingTrack(false);
            return 0;
          }
          return t + 0.1;
        });
      }, 100);
    } else {
      if (intervalRef.current) clearInterval(intervalRef.current);
    }
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [isPlayingBackingTrack, duration]);

  const loadBackingTrack = (name: string) => {
    setBackingTrackName(name);
    setDuration(120); // 2 mins mock
    setCurrentTime(0);
    setIsPlayingBackingTrack(false);
  };

  const toggleBackingTrack = () => {
    if (duration > 0) {
      setIsPlayingBackingTrack(!isPlayingBackingTrack);
    }
  };

  const stopBackingTrack = () => {
    setIsPlayingBackingTrack(false);
    setCurrentTime(0);
  };

  return { isPlayingBackingTrack, duration, currentTime, backingTrackName, loadBackingTrack, toggleBackingTrack, stopBackingTrack };
};

const formatTime = (time: number) => {
  const minutes = Math.floor(time / 60);
  const seconds = Math.floor(time % 60);
  return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
};

function App() {
  const recorderVM = useRecorderVM();
  const playbackVM = usePlaybackVM();

  // Load initial recordings mock
  useEffect(() => {
    recorderVM.fetchRecordings();
  }, []); // Run once

  const handleRecordButton = () => {
    if (recorderVM.isRecording) {
      recorderVM.stopRecording();
      playbackVM.stopBackingTrack();
    } else {
      recorderVM.startRecording();
      if (playbackVM.duration > 0) {
        playbackVM.toggleBackingTrack();
      }
    }
  };

  const handleImport = () => {
    // Mock import
    playbackVM.loadBackingTrack("Demo Track.mp3");
  };

  return (
    <div className="ios-mimic">
      <div className="status-bar">
        <span>9:41</span>
        <div className="status-icons">
          <div className="signal">Wait...</div>
          <div className="battery">100%</div>
        </div>
      </div>

      <div className="app-container">
        {/* Header */}
        <h1 className="header-title">Vocal Practice</h1>

        {/* Backing Track Section */}
        <div className="section">
          <h2 className="section-title">Backing Track</h2>
          <div className="card">
            <button
              className="play-button"
              onClick={playbackVM.toggleBackingTrack}
              disabled={playbackVM.duration === 0}
            >
              {playbackVM.isPlayingBackingTrack ? '⏸' : '▶'}
            </button>
            <div className="track-info">
              <div className="track-name">{playbackVM.backingTrackName || "No Track Loaded"}</div>
              {playbackVM.duration > 0 && (
                <div className="track-time">
                  {formatTime(playbackVM.currentTime)} / {formatTime(playbackVM.duration)}
                </div>
              )}
            </div>
          </div>
          <button className="import-button" onClick={handleImport}>Import Track</button>
        </div>

        <div className="spacer"></div>

        {/* Recording Controls */}
        <div className="recording-section">
          <div className="timer">{formatTime(recorderVM.recordingTime)}</div>

          {/* VU Meter */}
          <div className="vu-meter-container">
            <div className="vu-meter-bg"></div>
            <div
              className={`vu-meter-fill ${recorderVM.audioLevel > 0.8 ? 'red' : 'green'}`}
              style={{ width: `${recorderVM.audioLevel * 100}%` }}
            ></div>
          </div>

          <button className="record-button-container" onClick={handleRecordButton}>
            <div className="record-ring"></div>
            <div className={`record-core ${recorderVM.isRecording ? 'recording' : ''}`}></div>
          </button>
        </div>

        <div className="spacer"></div>

        {/* Recent Takes */}
        <div className="section">
          <h2 className="section-title">Recent Takes</h2>
          <div className="list">
            {recorderVM.recordings.length === 0 ? (
              <div className="empty-list">No recordings yet</div>
            ) : (
              recorderVM.recordings.map((rec, i) => (
                <div key={i} className="list-item">
                  <span>{rec}</span>
                  <button className="play-icon">▶</button>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      <div className="home-indicator"></div>
    </div>
  );
}

export default App;
