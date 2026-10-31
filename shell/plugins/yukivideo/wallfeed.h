#pragma once
// One decoded video for every window. A Qt Quick window can only show video that is decoded for it, so each window's
// Liquid Glass used to run its own player of the same wallpaper (bar, Dock, widgets, Spotlight, Settings ...), each a little
// out of step with the others. WallFeed is one sink for ONE MediaPlayer: every frame it gets is copied once into plain memory
// (a hardware frame belongs to the decoder's GPU context) and handed to every WallFeedOutput, which shows it in a VideoOutput
// of any window. Windows also say here whether they want the video (want()), so the single player knows when to play.
#include <QHash>
#include <QMetaObject>
#include <QMutex>
#include <QObject>
#include <QPointer>
#include <QVideoFrame>
#include <QVideoSink>
#include <QtQml/qqmlparserstatus.h>
#include <QtQml/qqmlregistration.h>

class WallFeed : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QObject *sink READ sink CONSTANT)                          // MediaPlayer.videoOutput
    Q_PROPERTY(bool hasFrame READ hasFrame NOTIFY hasFrameChanged)
    Q_PROPERTY(int watching READ watching NOTIFY wantsChanged)            // windows that want the video playing now
    Q_PROPERTY(int holding READ holding NOTIFY wantsChanged)              // windows that show it (playing or paused)
public:
    explicit WallFeed(QObject *parent = nullptr);
    QObject *sink() const { return m_sink; }
    bool hasFrame() const { return m_hasFrame; }
    int watching() const;
    int holding() const { return m_wants.size(); }
    QVideoFrame lastFrame() const;

    // key: any string unique to the window's LiveWall. playing = false: it shows the video but may be paused.
    Q_INVOKABLE void want(const QString &key, bool playing);
    Q_INVOKABLE void release(const QString &key);
    Q_INVOKABLE void clear();          // the player is gone: forget the last frame

signals:
    void frameReady(const QVideoFrame &frame);
    void hasFrameChanged();
    void wantsChanged();

private:
    void onFrame(const QVideoFrame &frame);   // decoder thread
    QVideoSink *m_sink;
    mutable QMutex m_lock;
    QVideoFrame m_last;
    bool m_hasFrame = false;
    QHash<QString, bool> m_wants;
};

class WallFeedOutput : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    QML_ELEMENT
    Q_PROPERTY(QObject *target READ target WRITE setTarget NOTIFY targetChanged)   // a VideoOutput's videoSink
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)  // false: keeps the last frame, takes no new ones
public:
    explicit WallFeedOutput(QObject *parent = nullptr);
    QObject *target() const { return m_target; }
    void setTarget(QObject *t);
    bool enabled() const { return m_enabled; }
    void setEnabled(bool on);
    void classBegin() override {}
    void componentComplete() override;

signals:
    void targetChanged();
    void enabledChanged();

private:
    void rewire();
    void push(const QVideoFrame &frame);
    QPointer<WallFeed> m_feed;         // the WallFeed singleton of this object's QML engine
    QPointer<QObject> m_target;
    bool m_enabled = true;
    QMetaObject::Connection m_conn;
};
