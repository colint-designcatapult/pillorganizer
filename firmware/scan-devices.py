import socket    
import multiprocessing
import subprocess
import os
import netifaces as nif
from getmac import get_mac_address
import webbrowser

esp_vendor_ids = ['8C:CE:4E', '3C:61:05', '0C:DC:7E', 'A0:76:4E', 'E0:E2:E6', 
                  '08:3A:F2', '94:B9:7E', 'E8:68:E7', 'E8:DB:84', '24:A1:60', 
                  'A8:03:2A', 'C4:DD:57', '24:6F:28', '80:7D:3A', '68:C6:3A', 
                  '24:0A:C4', '60:01:94', '90:97:D5', 'AC:D0:74', 'FC:F5:C4', 
                  '70:03:9F', '98:F4:AB', 'D8:BF:C0', '50:02:91', '24:62:AB', 
                  'A4:CF:12', 'CC:50:E3', 'BC:DD:C2', 'D8:A0:1D', '24:B2:DE', 
                  'A0:20:A6', '5C:CF:7F', '8C:AA:B5', '7C:DF:A1', 'AC:67:B2', 
                  'D8:F1:5B', 'C4:4F:33', '30:AE:A4', 'E0:98:06', 'F4:CF:A2', 
                  '10:52:1C', '40:F5:20', '84:CC:A8', 'C8:2B:96', '84:0D:8E', 
                  '84:F3:EB', 'A4:7B:9D', '18:FE:34', '48:3F:DA', 'F0:08:D1', 
                  '7C:9E:BD', 'B8:F0:09', '4C:11:AE', '2C:F4:32', '3C:71:BF', 
                  'B4:E6:2D', 'C4:5B:BE', 'BC:FF:4D', '34:AB:95', 'A8:48:FA', 
                  '34:B4:72', 'C8:C9:A3', '8C:4B:14', 'A4:E5:7C', 'EC:94:CB', 
                  '44:17:93', '4C:75:25', '9C:9C:1F', '98:CD:AC', '78:E3:6D', 
                  '34:86:5D', '84:F7:03', 'AC:0B:FB', '1C:9D:C2', '30:83:98', 
                  '40:91:51', '60:55:F9', '94:3C:C6', '7C:87:CE', '58:BF:25', 
                  '90:38:0C', '10:91:A8', '58:CF:79', '68:67:25', '34:94:54', 
                  '4C:EB:D6', 'D4:F9:8D', 'E8:9F:6D', '48:55:19', '70:B8:F6', 
                  '24:D7:EB', '30:C6:F7', '10:97:BD', '78:21:84', 'DC:4F:22', 
                  'EC:FA:BC', '2C:3A:E8', '54:5A:A6', 'E8:31:CD', 'B8:D6:1A']

def pinger(job_q, results_q):
    """
    Do Ping
    :param job_q:
    :param results_q:
    :return:
    """
    DEVNULL = open(os.devnull, 'w')
    while True:
        ip = job_q.get()

        if ip is None:
            break

        try:
            subprocess.check_output(['ping', '-c1', '1', ip])
            vendor_id = ':'.join(str(e).upper() for e in get_mac_address(ip=ip).split(':')[0:3])

            if(vendor_id in esp_vendor_ids):
                print('IP Address: {} Vendor ID: {}'.format(ip, vendor_id))
                webbrowser.open(ip + '/ota', new=0, autoraise=True)
                results_q.put(ip)
        except:
        	pass


def get_my_ip():
    """
    Find my IP address
    :return:
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    ip = s.getsockname()[0]
    s.close()
    return ip


def map_network(pool_size=255):
    """
    Maps the network
    :param pool_size: amount of parallel ping processes
    :return: list of valid ip addresses
    """

    ip_list = list()

    # get my IP and compose a base like 192.168.1.xxx
    ip_parts = get_my_ip().split('.')
    base_ip = ip_parts[0] + '.' + ip_parts[1] + '.' + ip_parts[2] + '.'

    # prepare the jobs queue
    jobs = multiprocessing.Queue()
    results = multiprocessing.Queue()

    pool = [multiprocessing.Process(target=pinger, args=(jobs, results)) for i in range(pool_size)]

    for p in pool:
        p.start()

    # cue the ping processes
    for i in range(1, 255):
        jobs.put(base_ip + '{0}'.format(i))

    for p in pool:
        jobs.put(None)

    for p in pool:
        p.join()

    # collect the results
    while not results.empty():
        ip = results.get()
        ip_list.append(ip)

    return ip_list

if __name__ == '__main__':
    print('Mapping...')
    lst = map_network()
    #vendor_id = ':'.join(str(e).upper() for e in get_mac_address(ip='192.168.2.91').split(':')[0:3])
    #print(vendor_id)
