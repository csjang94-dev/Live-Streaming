<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Live Streaming Player</title>

  <!-- CloudFront 설정 로드 -->
  <script src="cloudfront-config.js"></script>

  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      padding: 20px;
    }

    .container {
      background: white;
      border-radius: 20px;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
      max-width: 1200px;
      width: 100%;
      overflow: hidden;
    }

    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 30px;
      text-align: center;
      color: white;
    }

    .header h1 {
      font-size: 2.5em;
      margin-bottom: 10px;
      text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
    }

    .status {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(255, 255, 255, 0.2);
      padding: 8px 20px;
      border-radius: 20px;
      font-size: 1.1em;
      margin-top: 10px;
    }

    .status-dot {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      background: #ff4444;
      animation: pulse 2s infinite;
    }

    .status.live .status-dot {
      background: #44ff44;
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }

    .video-container {
      position: relative;
      background: #000;
      aspect-ratio: 16/9;
    }

    video {
      width: 100%;
      height: 100%;
      display: block;
    }

    .loading {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      color: white;
      font-size: 1.5em;
      text-align: center;
    }

    .spinner {
      border: 4px solid rgba(255, 255, 255, 0.3);
      border-top: 4px solid white;
      border-radius: 50%;
      width: 50px;
      height: 50px;
      animation: spin 1s linear infinite;
      margin: 0 auto 20px;
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }

    .controls {
      padding: 30px;
      background: #f8f9fa;
    }

    .input-group {
      margin-bottom: 20px;
    }

    .input-group label {
      display: block;
      margin-bottom: 8px;
      font-weight: 600;
      color: #333;
    }

    .input-group input {
      width: 100%;
      padding: 12px;
      border: 2px solid #ddd;
      border-radius: 8px;
      font-size: 1em;
      transition: border-color 0.3s;
    }

    .input-group input:focus {
      outline: none;
      border-color: #667eea;
    }

    .btn {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border: none;
      padding: 12px 30px;
      border-radius: 8px;
      font-size: 1.1em;
      cursor: pointer;
      transition: transform 0.2s, box-shadow 0.2s;
      width: 100%;
    }

    .btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
    }

    .btn:active {
      transform: translateY(0);
    }

    .info {
      margin-top: 20px;
      padding: 15px;
      background: #e3f2fd;
      border-left: 4px solid #2196f3;
      border-radius: 4px;
      font-size: 0.9em;
      color: #333;
    }

    .info strong {
      color: #1976d2;
    }

    .footer {
      text-align: center;
      padding: 20px;
      color: #666;
      font-size: 0.9em;
    }

    @media (max-width: 768px) {
      .header h1 {
        font-size: 1.8em;
      }
      
      body {
        padding: 10px;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🎥 Live Streaming</h1>
      <div class="status" id="status">
        <span class="status-dot"></span>
        <span id="status-text">대기 중</span>
      </div>
    </div>

    <div class="video-container">
      <video id="video" controls muted></video>
      <div class="loading" id="loading">
        <div class="spinner"></div>
        <div>스트림 연결 중...</div>
      </div>
    </div>

    <div class="controls">
      <div class="input-group">
        <label for="stream-url">🔗 HLS 스트림 URL</label>
        <input 
          type="text" 
          id="stream-url" 
          placeholder="https://your-bucket.s3.region.amazonaws.com/live/index.m3u8"
          value=""
        >
      </div>

      <button class="btn" onclick="loadStream()">
        ▶️ 스트림 시작
      </button>

      <div class="info">
        <strong>📝 사용 방법:</strong><br>
        1. Terraform으로 배포한 후 <code>terraform output hls_s3_url</code> 명령어로 URL 확인<br>
        2. 위 입력창에 URL 붙여넣기<br>
        3. MediaLive 채널 시작 (Lambda 또는 AWS CLI)<br>
        4. Larix Broadcaster로 스트리밍 시작<br>
        5. "스트림 시작" 버튼 클릭
      </div>
    </div>

    <div class="footer">
      Made with ❤️ using AWS MediaLive & Terraform
    </div>
  </div>

  <!-- HLS.js 라이브러리 -->
  <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
  
  <script>
    const video = document.getElementById('video');
    const loading = document.getElementById('loading');
    const status = document.getElementById('status');
    const statusText = document.getElementById('status-text');
    const urlInput = document.getElementById('stream-url');

    // 자동 URL 설정 - 버킷명과 리전만 수정하세요!
    const BUCKET_NAME = "${BUCKET_NAME}";
    const REGION = "${REGION}";
    
    // CloudFront URL 우선, 없으면 S3 사용
    const AUTO_STREAM_URL = typeof CLOUDFRONT_HLS_URL !== 'undefined' 
      ? CLOUDFRONT_HLS_URL 
      : `https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com/live.m3u8`;

    let hls = null;

    // 페이지 로드 시 자동 URL 설정
    window.addEventListener('load', () => {
      const savedUrl = localStorage.getItem('streamUrl');
      if (savedUrl) {
        urlInput.value = savedUrl;
      } else {
        urlInput.value = AUTO_STREAM_URL; // 자동 URL 사용
      }
      
      // 자동 재생 시도
      setTimeout(() => {
        loadStream();
      }, 500);
    });

    function updateStatus(text, isLive = false) {
      statusText.textContent = text;
      if (isLive) {
        status.classList.add('live');
      } else {
        status.classList.remove('live');
      }
    }

    function loadStream() {
      const streamUrl = urlInput.value.trim();
      
      if (!streamUrl) {
        alert('스트림 URL을 입력해주세요!');
        return;
      }

      // URL 저장
      localStorage.setItem('streamUrl', streamUrl);

      // 로딩 표시
      loading.style.display = 'block';
      updateStatus('연결 중...', false);

      // 기존 스트림 정리
      if (hls) {
        hls.destroy();
      }

      // HLS.js 지원 확인
      if (Hls.isSupported()) {
        hls = new Hls({
          enableWorker: true,
          lowLatencyMode: true,
          backBufferLength: 90
        });

        hls.loadSource(streamUrl);
        hls.attachMedia(video);

        // 이벤트 핸들러
        hls.on(Hls.Events.MANIFEST_PARSED, function() {
          loading.style.display = 'none';
          updateStatus('🟢 LIVE', true);
          video.play().catch(e => {
            console.log('자동 재생 실패:', e);
            updateStatus('🟡 재생 버튼을 눌러주세요', false);
          });
        });

        hls.on(Hls.Events.ERROR, function(event, data) {
          console.error('HLS 에러:', data);
          
          if (data.fatal) {
            switch(data.type) {
              case Hls.ErrorTypes.NETWORK_ERROR:
                updateStatus('🔴 네트워크 오류 - 재연결 시도 중...', false);
                hls.startLoad();
                break;
              case Hls.ErrorTypes.MEDIA_ERROR:
                updateStatus('🔴 미디어 오류 - 복구 시도 중...', false);
                hls.recoverMediaError();
                break;
              default:
                updateStatus('🔴 스트림 오프라인', false);
                hls.destroy();
                loading.style.display = 'block';
                break;
            }
          }
        });

        hls.on(Hls.Events.FRAG_LOADED, function() {
          if (loading.style.display !== 'none') {
            loading.style.display = 'none';
          }
        });

      } 
      // Safari - 네이티브 HLS 지원
      else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = streamUrl;
        
        video.addEventListener('loadedmetadata', function() {
          loading.style.display = 'none';
          updateStatus('🟢 LIVE', true);
          video.play().catch(e => {
            console.log('자동 재생 실패:', e);
            updateStatus('🟡 재생 버튼을 눌러주세요', false);
          });
        });

        video.addEventListener('error', function() {
          updateStatus('🔴 스트림 오프라인', false);
          loading.style.display = 'block';
        });
      } else {
        alert('이 브라우저는 HLS 스트리밍을 지원하지 않습니다.');
        loading.style.display = 'none';
      }
    }

    // Enter 키로 스트림 로드
    urlInput.addEventListener('keypress', function(e) {
      if (e.key === 'Enter') {
        loadStream();
      }
    });

    // 비디오 재생/일시정지 이벤트
    video.addEventListener('play', function() {
      if (status.classList.contains('live')) {
        updateStatus('🟢 LIVE', true);
      }
    });

    video.addEventListener('pause', function() {
      if (status.classList.contains('live')) {
        updateStatus('⏸️ 일시정지', true);
      }
    });
  </script>
</body>
</html>
