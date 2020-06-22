"""
    Datadog custom monitoring check
"""

from urllib.request import urlopen
import json
from datetime import datetime
from datadog_checks.base.checks import AgentCheck


def get_index_age(site):
    """
        get_index_age returns pluginsite api age
    """
    url = "https://{0}/api/health/elasticsearch".format(site)
    health_status = urlopen(url).read()
    index_creation = datetime.strptime(json.loads(health_status)['createdAt'],
                                       '%Y-%m-%dT%H:%M:%S')
    age = datetime.today() - index_creation
    return age.seconds / 3600

class PluginsApiCheck(AgentCheck):
    """
        Return pluginsite elasticsearch index age in hour
    """
    def check(self, instance):

        """ check tests if the monitoring test is successfull or not"""

        metric = 'plugins.index.age'
        site = instance['site']
        tag = "site:" + site
        self.gauge(metric, get_index_age(site), tags=[tag])
