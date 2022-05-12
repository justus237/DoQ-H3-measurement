from datetime import datetime
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as chromeOptions
from selenium.webdriver.support.ui import WebDriverWait
import sys
#setup
#need server ip
try:
    server_ip = sys.argv[1]
    msm_id = sys.argv[2]
except IndexError:
    print(
        'Input params incomplete, need server IP address for host mapping'
    )
    sys.exit(1)
#need server certificate hash
with open('cert_fingerprint.txt', 'r') as f:
	cert_hash = f.read().rstrip()


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
#required to run as sudo
chrome_options.add_argument("--no-sandbox")
#need x forwarding ($DISPLAY) if commented out
chrome_options.add_argument('--headless')
#capture netlogs just in case, use timestamp for file name for now
chrome_options.add_argument("--net-log-capture-mode=Everything")
chrome_options.add_argument('--log-net-log=/home/quic_net03/chromium/chrome-netlog-'+timestamp.strftime("%y-%m-%d-%H:%M:%S")+'.json')

chrome_options.add_argument("--disable-dev-shm-usage")
#not used anymore but was needed for older youtube measurements
chrome_options.add_argument("--autoplay-policy=no-user-gesture-required")

#allows us to skip any CA setup
chrome_options.add_argument('--ignore-certificate-errors-spki-list='+cert_hash)
#need to fix it to IETF QUIC v1 because of client session cache serialization
chrome_options.add_argument('--quic-version=QUIC_VERSION_IETF_RFC_V1')
#this is probably not needed
chrome_options.add_argument('--ignore-urlfetcher-cert-requests')
#take the result we got from name resolution
#if you put quotes anywhere inside this one, it wont pass the argument properly when using selenium
chrome_options.add_argument("--host-resolver-rules=MAP www.example.org:443 "+server_ip+":6121")
#disable http cache so that the 0-rtt reload actually fetches the complete website again
chrome_options.add_argument('--disable-http-cache')
#force quic on the website under test
#alternative: '--origin-to-force-quic-on=*' (the star requires quotes when using this option on the command line)
chrome_options.add_argument('--origin-to-force-quic-on=www.example.org:443')
#enable quic
chrome_options.add_argument('--enable-quic')
#write key log for wireshark later on
chrome_options.add_argument('--ssl-key-log-file=/home/quic_net03/chromium/ssl_key_log.txt')

chrome_options.binary_location = "/home/quic_net03/chromium/src/out/Default/chrome"
driver = webdriver.Chrome(options=chrome_options, executable_path='/home/quic_net03/chromium/src/out/Default/chromedriver')

print(msm_id+": server cert: "+cert_hash+" on "+server_ip+", client chromium version: "+driver.capabilities['browserVersion'])
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
with open('/tmp/chrome_session_cache.txt', 'r') as f:
    print(f.read())
#sleep to wait for session timeout, causing 0-rtt to kick in
time.sleep(30)
driver.refresh()
while driver.execute_script("return document.readyState;") != "complete":
        time.sleep(1)
performance_metrics = driver.execute_script(web_perf_script)
print(performance_metrics)
driver.quit()