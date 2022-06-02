from datetime import datetime
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as chromeOptions
from selenium.webdriver.support.ui import WebDriverWait
import selenium.common.exceptions
import sys
import sqlite3
import re
#setup
#need server ip
try:
    server_ip = sys.argv[1]
    msm_id = sys.argv[2]
    timestamp = sys.argv[3]
    experiment_type = sys.argv[4]
    website = sys.argv[5]
    error = sys.argv[6]
    if error != "none":
        error = "DNS: "+error+"; "
    else:
        error = ""
except IndexError:
    print(
        'Input params incomplete, need server IP address for host mapping, measurement ID, timestamp, experiment type, website under test and previous dns errors'
    )
    sys.exit(1)
#need server certificate hash
with open('cert_fingerprint.txt', 'r') as f:
	cert_hash = f.read().rstrip()

measurement_elements_web_perf = (
    'msm_id', 'connectEnd', 'connectStart', 'domComplete',
    'domContentLoadedEventEnd', 'domContentLoadedEventStart', 'domInteractive', 'domainLookupEnd', 'domainLookupStart',
    'duration', 'encodedBodySize', 'decodedBodySize', 'transferSize', 'fetchStart', 'loadEventEnd', 'loadEventStart',
    'requestStart', 'responseEnd', 'responseStart', 'secureConnectionStart', 'startTime', 'firstPaint',
    'firstContentfulPaint', 'nextHopProtocol', 'redirectStart', 'redirectEnd', 'redirectCount', 'timeOrigin', 'is_warmup', 'domain_name')

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
#timestamp = datetime.now()
def get_chrome_options():
    chrome_options = chromeOptions()
    #required to run as sudo
    chrome_options.add_argument("--no-sandbox")
    #need x forwarding ($DISPLAY) if commented out
    chrome_options.add_argument('--headless')
    #capture netlogs just in case, use timestamp for file name for now
    #chrome_options.add_argument("--net-log-capture-mode=Everything")
    #chrome_options.add_argument('--log-net-log=chrome-netlog-'+timestamp+'-'+experiment_type+'-'+msm_id+'.json')#.strftime("%y-%m-%d-%H:%M:%S")+'.json')

    chrome_options.add_argument("--disable-dev-shm-usage")
    #not used anymore but was needed for older youtube measurements
    chrome_options.add_argument("--autoplay-policy=no-user-gesture-required")

    #allows us to skip any CA setup
    chrome_options.add_argument('--ignore-certificate-errors-spki-list='+cert_hash)
    #need to fix it to IETF QUIC v1 because of client session cache serialization, could probably just write h3
    chrome_options.add_argument('--quic-version=QUIC_VERSION_IETF_RFC_V1')
    #this is probably not needed
    chrome_options.add_argument('--ignore-urlfetcher-cert-requests')
    #take the result we got from name resolution
    #if you put quotes anywhere inside this one, it wont pass the argument properly when using selenium
    chrome_options.add_argument("--host-resolver-rules=MAP www.localdomain.com:443 "+server_ip+":6121")
    #disable http cache so that the 0-rtt reload actually fetches the complete website again
    chrome_options.add_argument('--disable-http-cache')
    #force quic on the website under test
    #alternative: '--origin-to-force-quic-on=*' (the star requires quotes when using this option on the command line)
    chrome_options.add_argument('--origin-to-force-quic-on=www.localdomain.com:443')
    #chrome_options.add_argument('--origin-to-force-quic-on=*')
    #enable quic
    chrome_options.add_argument('--enable-quic')
    #write key log for wireshark later on
    chrome_options.add_argument('--ssl-key-log-file='+msm_id+'-ssl_key_log.txt')

    #chrome_options.binary_location = "/home/quic_net03/chromium/src/out/Default/chrome"
    return chrome_options


def run_web_performance():
    chrome_options = get_chrome_options()
    driver = webdriver.Chrome(options=chrome_options)#, executable_path='/home/quic_net03/chromium/src/out/Default/chromedriver')
    
    print(timestamp+", "+experiment_type+", "+website+", "+msm_id+": server cert: "+cert_hash+" on "+server_ip+", client chromium version: "+driver.capabilities['browserVersion'])
    driver.set_page_load_timeout(30)
    try:
        #driver.get("https://www.example.org")
        driver.get("https://www.localdomain.com")
        #while driver.execute_script("return document.readyState;") != "complete":
        #    time.sleep(1)
        #https://stackoverflow.com/a/14901494
        WebDriverWait(driver, 20, 0.1).until(lambda x: x.execute_script('return document.readyState') == 'complete')
        #need to sleep otherwise first (contentful) paint will be 0
        time.sleep(2)
        performance_metrics_warmup = driver.execute_script(web_perf_script)
        #print(performance_metrics_warmup)
        if 'www.localdomain.com' not in performance_metrics_warmup['name']:
            driver.save_screenshot(website+"-"+experiment_type+'-warmup.png')
            print('something failed with chrome loading' + website + 'without crashing it')
            print(performance_metrics_warmup['name'])
            insert_measurement(error+"H3_web_performance_warmup chrome error "+performance_metrics_warmup['name'])
            insert_lookups()
            driver.quit()
            return
    except selenium.common.exceptions.WebDriverException as e:
        insert_measurement(error+"H3_web_performance_warmup: "+str(e))
        insert_lookups()
        driver.quit()
        print(str(e))
        return
    insert_web_performance(performance_metrics_warmup, 1)
    time.sleep(30)
    #with open('/tmp/chrome_session_cache.txt', 'r') as f:
    #    print(f.read())
    #sleep to wait for session timeout, causing 0-rtt to kick in
    try:
        driver.refresh()
        #while driver.execute_script("return document.readyState;") != "complete":
        #        time.sleep(1)
        WebDriverWait(driver, 20, 0.1).until(lambda x: x.execute_script('return document.readyState') == 'complete')
        #need to sleep otherwise first (contentful) paint will be 0
        time.sleep(2)
        performance_metrics = driver.execute_script(web_perf_script)
        #print(performance_metrics)
        if 'www.localdomain.com' not in performance_metrics['name']:
            driver.save_screenshot(website+"-"+experiment_type+'.png')
            print('something failed with chrome loading' + website + 'without crashing it')
            print(performance_metrics['name'])
            insert_measurement(error+"H3_web_performance chrome error "+performance_metrics_warmup['name'])
            insert_lookups()
            driver.quit()
            return
    except selenium.common.exceptions.WebDriverException as e:
        insert_measurement(error+"H3_web_performance: "+str(e))
        insert_lookups()
        driver.quit()
        print(str(e))
        return
    insert_web_performance(performance_metrics, 0)
    driver.quit()
    insert_measurement(error+"")
    insert_lookups()
    

db = sqlite3.connect("web-performance.db")
cursor = db.cursor()

def create_measurements_table():
    cursor.execute(
        """
            CREATE TABLE IF NOT EXISTS measurements (
                msm_id string,
                timestamp string,
                experiment_type string,
                error string,
                website string,
                PRIMARY KEY (msm_id)
            );
            """
    )
    db.commit()

def create_dns_metrics_table():
    cursor.execute(
        """
            CREATE TABLE IF NOT EXISTS dns_metrics (
                msm_id string,
                metric string,
                is_warmup string,
                transport_protocol string,
                FOREIGN KEY (msm_id) REFERENCES measurements(msm_id)
            );
            """
    )
    db.commit()

def create_web_performance_table():
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS web_performance_metrics (
            msm_id string,
            connectEnd double,
            connectStart double,
            domComplete double,
            domContentLoadedEventEnd double,
            domContentLoadedEventStart double,
            domInteractive double,
            domainLookupEnd double,
            domainLookupStart double,
            duration integer,
            encodedBodySize integer,
            decodedBodySize integer,
            transferSize integer,
            fetchStart double,
            loadEventEnd double,
            loadEventStart double,
            requestStart double,
            responseEnd double,
            responseStart double,
            secureConnectionStart double,
            startTime double,
            firstPaint double,
            firstContentfulPaint double,
            nextHopProtocol string,
            redirectStart double,
            redirectEnd double,
            redirectCount integer,
            timeOrigin datetime,
            is_warmup integer,
            domain_name string,
            FOREIGN KEY (msm_id) REFERENCES measurements(msm_id)
        );
        """)
    db.commit()

def create_lookups_table():
    cursor.execute(
        """
            CREATE TABLE IF NOT EXISTS lookups (
                msm_id string,
                domain string,
                elapsed numeric,
                status string,
                answer string,
                is_warmup integer,
                transport_protocol string,
                FOREIGN KEY (msm_id) REFERENCES measurements(msm_id)
            );
            """
    )
    db.commit()


def insert_web_performance(performance, is_warmup):
    performance['msm_id'] = msm_id
    performance['is_warmup'] = is_warmup
    performance['domain_name'] = performance['name']
    # insert into database
    cursor.execute(f"""
    INSERT INTO web_performance_metrics VALUES ({(len(measurement_elements_web_perf) - 1) * '?,'}?);
    """, tuple([performance[m_e] for m_e in measurement_elements_web_perf]))
    db.commit()

def insert_measurement(error):
    cursor.execute("INSERT INTO measurements VALUES (?,?,?,?,?);", (msm_id, timestamp, experiment_type, error, website))
    db.commit()

def insert_lookup(domain, elapsed, status, answer, is_warmup, transport_protocol):
    cursor.execute(
        """
    INSERT INTO lookups VALUES (?,?,?,?,?,?,?);
    """,
        (msm_id, domain, elapsed, status, answer, is_warmup, transport_protocol),
    )
    db.commit()

def insert_dns_metric(transport_protocol, metric, is_warmup):
    cursor.execute(
        """
    INSERT INTO dns_metrics VALUES (?,?,?,?);
    """,
        (msm_id, metric, is_warmup, transport_protocol),
    )
    db.commit()


def insert_lookups():
    #'dnsproxy-doq-warmup.log', 
    for file_name in ['dnsproxy-doq.log', 'dnsproxy-doh.log', 'dnsproxy-doudp.log']:
        with open(file_name, "r") as logs:
            if 'warmup' in file_name:
                is_warmup = True
            else:
                is_warmup = False
            if 'doq' in file_name:
                transport_protocol='DoQ'
            elif 'doh' in file_name:
                transport_protocol='DoH'
            elif 'doudp' in file_name:
                transport_protocol='DoUDP'
            else:
                transport_protocol='DoX'
            lines = logs.readlines()
            currently_parsing = ""
            domain = ""
            elapsed = 0.0
            status = ""
            answer = ""

            for line in lines:
                # upon success
                if "successfully finished exchange" in line:
                    currently_parsing = "success"
                    domain = re.search("exchange of ;(.*)IN",
                                        line).group(1).rstrip()
                    elapsed = re.search("Elapsed (.*)ms", line)
                    factor = 1.0
                    if elapsed is None:
                        elapsed = re.search("Elapsed (.*)µs", line)
                        factor = 1.0 / 1000.0
                    if elapsed is None:
                        elapsed = re.search("Elapsed (.*)s", line)
                        factor = 1000.0
                    elapsed = float(elapsed.group(1)) * factor
                # upon failure
                elif "failed to exchange" in line:
                    currently_parsing = "failure"
                    domain = re.search(
                        "failed to exchange ;(.*)IN", line).group(1).rstrip()
                    answer = re.search("Cause: (.*)", line).group(1).rstrip()
                    elapsed = re.search("in (.*)ms\\.", line)
                    factor = 1.0
                    if elapsed is None:
                        elapsed = re.search("in (.*)µs\\.", line)
                        factor = 1.0 / 1000.0
                    if elapsed is None:
                        elapsed = re.search("in (.*)s\\.", line)
                        factor = 1000.0
                    elapsed = float(elapsed.group(1)) * factor
                elif "metrics:" in line:
                    insert_dns_metric(transport_protocol, line, is_warmup)
                elif currently_parsing == "":
                    pass
                elif ", status: " in line:
                    status = re.search(", status: (.*),", line).group(1)
                    # if failure the parsing stops here, else we wait for the answer section
                    if currently_parsing == "failure":
                        insert_lookup(domain, elapsed, status, answer, is_warmup, transport_protocol)
                        currently_parsing = ""
                elif ";; ANSWER SECTION:" in line:
                    currently_parsing = "answer"
                    answer = ""
                elif currently_parsing == "answer":
                    # in this case we finished parsing the answer section
                    if line.rstrip() == "":
                        insert_lookup(domain, elapsed, status, answer, is_warmup, transport_protocol)
                        currently_parsing = ""
                    else:
                        answer += ",".join(line.split())
                        answer += "|"



create_measurements_table()
create_web_performance_table()
create_dns_metrics_table()
create_lookups_table()

run_web_performance()

db.close()