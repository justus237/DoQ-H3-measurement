from datetime import datetime
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as chromeOptions
from selenium.webdriver.support.ui import WebDriverWait
import sys
from pathlib import Path
#setup
#need server ip
try:
    server_ip = sys.argv[1]
except IndexError:
    print(
        'Input params incomplete, need server IP address for host mapping'
    )
    sys.exit(1)
#need server certificate hash
cert_hash = Path('cert_fingerprint.txt').read_text()
print(cert_hash)

web_perf_script = """
            // Get performance and paint entries
            var perfEntries = performance.getEntriesByType("navigation");
            var paintEntries = performance.getEntriesByType("paint");
    
            var entry = perfEntries[0];
            var fpEntry = paintEntries[0];
            var fcpEntry = paintEntries[1];
    
            // Get the JSON and first paint + first contentful paint
            var resultJson = entry.toJSON();
            resultJson.firstPaint = 0;
            resultJson.firstContentfulPaint = 0;
            try {
                for (var i=0; i<paintEntries.length; i++) {
                    var pJson = paintEntries[i].toJSON();
                    if (pJson.name == 'first-paint') {
                        resultJson.firstPaint = pJson.startTime;
                    } else if (pJson.name == 'first-contentful-paint') {
                        resultJson.firstContentfulPaint = pJson.startTime;
                    }
                }
            } catch(e) {}
            resultJson.timeOrigin = performance.timeOrigin;
            
            return resultJson;
            """
timestamp = datetime.now()
chrome_options = chromeOptions()
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument('--headless')
chrome_options.add_argument("--net-log-capture-mode=Everything")
chrome_options.add_argument('--log-net-log=/home/quic_net03/chromium/chrome-netlog-'+timestamp.strftime("%y-%m-%d-%H:%M:%S")+'.json')
chrome_options.add_argument("--disable-dev-shm-usage")
chrome_options.add_argument(
    "--autoplay-policy=no-user-gesture-required")
#coredns cert
#chrome_options.add_argument('--ignore-certificate-errors-spki-list=RSu3xgjFRjm1T5iTlXhHFzneE8mSyYaMNNoLse+kvpc=')
#epoll_quic_server cert
#chrome_options.add_argument('--ignore-certificate-errors-spki-list=Y0DT195ejww1gZ+evc5QBpU5sB376m1DU/g+lDqBLcw=')
chrome_options.add_argument('--ignore-certificate-errors-spki-list='+cert_hash)
chrome_options.add_argument('--quic-version=QUIC_VERSION_IETF_RFC_V1')
chrome_options.add_argument('--ignore-urlfetcher-cert-requests')
chrome_options.add_argument("--host-resolver-rules=MAP www.example.org:443 "+server_ip+":6121")
chrome_options.add_argument('--disable-http-cache')
chrome_options.add_argument('--origin-to-force-quic-on=www.example.org:443')
chrome_options.add_argument('--enable-quic')
chrome_options.add_argument('--ssl-key-log-file=/home/quic_net03/chromium/ssl_key_log.txt')
chrome_options.binary_location = "/home/quic_net03/chromium/src/out/Default/chrome"
driver = webdriver.Chrome(options=chrome_options, executable_path='/home/quic_net03/chromium/src/out/Default/chromedriver')
#executable_path='src/out/Default/chromedriver', options=chrome_options)
print(driver.capabilities['browserVersion'])
driver.set_page_load_timeout(30)
#driver.get("https://www.google.com")
#driver.get("https://blog.cloudflare.com/content/images/2019/01/quiche-1.png")
#driver.get("https://www.example.org/demo/tile")
#driver.get("https://www.example.org/tile.png")
driver.get("https://www.example.org")
while driver.execute_script("return document.readyState;") != "complete":
	time.sleep(1)
#time.sleep(10)
performance_metrics = driver.execute_script(web_perf_script)
print(performance_metrics)
#with open('/tmp/chrome_session_cache.txt', 'r') as f:
#    print(f.read())
print(Path('/tmp/chrome_session_cache.txt').read_text())
#sleep to wait for session timeout, causing 0-rtt to kick in
time.sleep(30)
driver.refresh()
while driver.execute_script("return document.readyState;") != "complete":
        time.sleep(1)
performance_metrics = driver.execute_script(web_perf_script)
print(performance_metrics)
driver.quit()